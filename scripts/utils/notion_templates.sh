#!/bin/bash  
set -euo pipefail  
shopt -s failglob nocasematch  
  
### [КОНФИГУРАЦИЯ] ###  
readonly VERSION="2.2.0"  
readonly WORK_DIR="${HOME}/notion_templates"  
readonly LOCK_FILE="${WORK_DIR}/.lock"  
readonly LOG_FILE="${WORK_DIR}/templates.log"  
readonly MAX_LOG_SIZE=5242880  # 5MB  
readonly MAX_RETRIES=5  
readonly LOCK_TIMEOUT=120  
  
### [СХЕМЫ ТАБЛИЦ] ###  
declare -A TEMPLATES=(  
  ["wz_tasks.csv"]="id,title,status,priority,project,due_date,created_at,updated_at"  
  ["wz_projects.csv"]="id,name,repository,description,status,owner,start_date,end_date"  
  ["wz_systems.csv"]="id,name,purpose,components,status,created_at"  
  ["wz_environments.csv"]="id,name,type,ip_address,status,purpose"  
  ["wz_versions.csv"]="id,component,version,date,change_summary"  
  ["wz_notes.csv"]="id,title,content,tags,created_at,updated_at"  
  ["wz_bookmarks.csv"]="id,url,title,description,tags,category"  
  ["wz_insights.csv"]="id,context,insight,source,date"  
  ["wz_chats.csv"]="id,title,start_time,end_time,participants,related_tasks"  
  ["wz_chat_summaries.csv"]="id,chat_title,summary,tags,created_at"  
  ["wz_personas.csv"]="id,name,role,email,status,skills"  
  ["wz_habits.csv"]="id,name,category,streak,last_completed,target"  
  ["wz_links.csv"]="id,source_type,source_id,target_type,target_id,relation"  
  ["wz_events.csv"]="id,name,date,description,related_to,status"  
  ["wz_logs.csv"]="id,timestamp,event_type,description,related_script,status"  
  ["wz_scripts.csv"]="id,name,path,description,version,last_updated,status"  
)  
  
### [ФУНКЦИИ БЕЗОПАСНОСТИ] ###  
validate_path() {  
  [[ "$WORK_DIR" =~ ^${HOME}/[a-zA-Z0-9_/-]+$ ]] || {  
    log "ERROR" "Invalid path specification"  
    return 1  
  }  
  return 0  
}  
  
check_disk_space() {  
  local min_space=${1:-10000}  # 10MB по умолчанию  
  local free_kb=$(df -k --output=avail "$HOME" | awk 'NR==2 {print $1}')  
    
  (( free_kb >= min_space )) || {  
    log "ERROR" "Insufficient disk space: ${free_kb}KB available, ${min_space}KB required"  
    return 1  
  }  
  return 0  
}  
  
sanitize_content() {  
  local content="$1"  
  # Безопасная обработка CSV-контента  
  echo "$content" | awk '{  
    gsub(/[\r\n\t"`$\\]/, "");  # Удаляем опасные символы  
    gsub(/, */, ",");           # Нормализуем пробелы после запятых  
    gsub(/\|/, " ");            # Заменяем pipe-символы  
    print  
  }'  
}  
  
### [ФУНКЦИИ ЛОГИРОВАНИЯ] ###  
init_logging() {  
  mkdir -p "$(dirname "$LOG_FILE")" || {  
    echo "Failed to initialize logging" >&2  
    return 1  
  }  
  [[ -f "$LOG_FILE" ]] && rotate_logs  
  return 0  
}  
  
rotate_logs() {  
  local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)  
  (( size > MAX_LOG_SIZE )) && {  
    mv -f "$LOG_FILE" "${LOG_FILE}.old" || {  
      echo "Log rotation failed" >&2  
      return 1  
    }  
    log "INFO" "Rotated log file"  
  }  
  return 0  
}  
  
log() {  
  local level="$1" message="$2"  
  local timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)  
  local safe_message=$(echo "$message" | tr -d '\n\r')  
    
  printf '{"time":"%s","level":"%s","pid":%d,"message":"%s"}\n' \  
    "$timestamp" "$level" $$ "$safe_message" >> "$LOG_FILE" || {  
    echo "Log write failed: $level - $message" >&2  
  }  
}  
  
### [ОСНОВНЫЕ ФУНКЦИИ] ###  
acquire_lock() {  
  local retry=0  
  while (( retry < MAX_RETRIES )); do  
    if (set -o noclobber; echo $$ > "$LOCK_FILE") 2>/dev/null; then  
      trap 'release_lock' EXIT SIGINT SIGTERM  
      log "DEBUG" "Lock acquired"  
      return 0  
    fi  
      
    local lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)  
    if [[ -n "$lock_pid" ]]; then  
      if ! ps -p "$lock_pid" >/dev/null; then  
        rm -f "$LOCK_FILE" && continue  
      else  
        log "DEBUG" "Lock held by process $lock_pid, waiting..."  
      fi  
    fi  
      
    sleep $(( (RANDOM % 3) + 1 ))  
    (( retry++ ))  
  done  
    
  log "ERROR" "Failed to acquire lock after $MAX_RETRIES attempts"  
  return 1  
}  
  
release_lock() {  
  [[ -f "$LOCK_FILE" ]] && [[ $(cat "$LOCK_FILE") == $$ ]] && {  
    rm -f "$LOCK_FILE"  
    log "DEBUG" "Lock released"  
  }  
  return 0  
}  
  
create_templates() {  
  local count=0 errors=0  
  for file in "${!TEMPLATES[@]}"; do  
    local target="${WORK_DIR}/${file}"  
    [[ -f "$target" ]] && continue  
      
    local content=$(sanitize_content "${TEMPLATES[$file]}")  
    if echo "$content" > "$target.tmp"; then  
      if mv -f "$target.tmp" "$target"; then  
        log "INFO" "Created template: $file"  
        (( count++ ))  
      else  
        log "ERROR" "Failed to finalize: $file"  
        (( errors++ ))  
        rm -f "$target.tmp"  
      fi  
    else  
      log "ERROR" "Failed to create: $file"  
      (( errors++ ))  
    fi  
  done  
    
  (( errors > 0 )) && log "WARN" "Encountered $errors errors during template creation"  
  echo "$count"  
}  
  
list_templates() {  
  local templates=()  
  while IFS= read -r -d $'\0' file; do  
    templates+=("$(basename "$file")")  
  done < <(find "$WORK_DIR" -maxdepth 1 -type f -name 'wz_*.csv' -print0 2>/dev/null)  
    
  if (( ${#templates[@]} > 0 )); then  
    printf "%s\n" "${templates[@]}" | sort  
  else  
    log "WARN" "No templates found"  
    return 1  
  fi  
}  
  
### [КОМАНДЫ] ###  
cmd_init() {  
  log "INFO" "Initializing templates"  
  validate_path || return 1  
  check_disk_space || return 1  
  acquire_lock || return 1  
    
  mkdir -p "$WORK_DIR" || {  
    log "ERROR" "Failed to create directory: $WORK_DIR"  
    return 1  
  }  
    
  local created=$(create_templates)  
  if (( created > 0 )); then  
    log "INFO" "Successfully created $created templates"  
    echo "Created $created new templates in $WORK_DIR"  
    return 0  
  else  
    log "INFO" "No new templates created (already exist)"  
    echo "All templates already exist in $WORK_DIR"  
    return 0  
  fi  
}  
  
cmd_list() {  
  log "INFO" "Listing templates"  
  if list_templates; then  
    return 0  
  else  
    log "ERROR" "Failed to list templates"  
    echo "No templates found in $WORK_DIR" >&2  
    return 1  
  fi  
}  
  
cmd_clean() {  
  log "WARN" "Cleaning templates"  
  acquire_lock || return 1  
    
  local count=0  
  while IFS= read -r -d $'\0' file; do  
    if rm -f "$file"; then  
      (( count++ ))  
      log "INFO" "Removed: $(basename "$file")"  
    else  
      log "ERROR" "Failed to remove: $(basename "$file")"  
    fi  
  done < <(find "$WORK_DIR" -maxdepth 1 -type f -name 'wz_*.csv' -print0 2>/dev/null)  
    
  if (( count > 0 )); then  
    log "INFO" "Removed $count templates"  
    echo "Removed $count templates from $WORK_DIR"  
    return 0  
  else  
    log "INFO" "No templates to remove"  
    echo "No templates found in $WORK_DIR"  
    return 0  
  fi  
}  
  
### [ТОЧКА ВХОДА] ###  
main() {  
  if ! init_logging; then  
    echo "Initialization failed" >&2  
    exit 1  
  fi  
    
  log "INFO" "Process started (PID: $$, Args: $*)"  
    
  case "${1:-help}" in  
    init)    cmd_init ;;  
    list)    cmd_list ;;  
    clean)   cmd_clean ;;  
    version) echo "Notion Templates Manager v$VERSION" ;;  
    help|*)  
      echo "Usage: ${0##*/} [command]"  
      echo "Commands:"  
      echo "  init     - Create all templates"  
      echo "  list     - Show available templates"  
      echo "  clean    - Remove all templates"  
      echo "  version  - Show version"  
      echo "  help     - Show this help"  
      ;;  
  esac  
    
  log "INFO" "Process completed"  
  exit 0  
}  
  
main "$@"
