set -euo pipefail

### [КОНФИГУРАЦИЯ] ###
readonly VERSION="2.2.0-termux"
readonly WORK_DIR="${HOME}/storage/shared/Notion_Templates"
readonly LOCK_FILE="${TMPDIR}/notion_templates.lock"
readonly MAX_RETRIES=3

### [СХЕМЫ ТАБЛИЦ] ###
declare -A TEMPLATES=(
  ["tasks.csv"]="id,title,status,priority,project,due_date"
  ["projects.csv"]="id,name,description,status,owner"
  ["notes.csv"]="id,title,content,tags,created_at"
  ["bookmarks.csv"]="id,url,title,description,tags"
  ["ideas.csv"]="id,title,description,tags,created_at"
  ["meetings.csv"]="id,date,time,topic,participants,notes"
  ["habits.csv"]="id,habit,frequency,status,last_checked"
  ["expenses.csv"]="id,date,amount,category,description"
  ["income.csv"]="id,date,source,amount,notes"
  ["clients.csv"]="id,name,email,phone,company,notes"
  ["invoices.csv"]="id,client,date,due,amount,status"
  ["deliveries.csv"]="id,order_id,date,status,comments"
  ["bugs.csv"]="id,title,description,severity,status"
  ["roadmap.csv"]="id,feature,description,status,release"
)

### [ФУНКЦИИ БЕЗОПАСНОСТИ] ###
check_termux_env() {
  if ! [ -d "/data/data/com.termux/files" ]; then
    echo "Ошибка: Скрипт должен запускаться в Termux" >&2
    return 1
  fi
  if ! termux-setup-storage; then
    echo "Ошибка: Не удалось получить доступ к хранилищу" >&2
    return 1
  fi
}

validate_path() {
  [[ "$WORK_DIR" == */Notion_Templates ]] || {
    echo "Недопустимый путь к хранилищу" >&2
    return 1
  }
}

### [ОСНОВНЫЕ ФУНКЦИИ] ###
acquire_lock() {
  local retry=0
  while (( retry < MAX_RETRIES )); do
    if (set -o noclobber; echo $$ > "$LOCK_FILE") 2>/dev/null; then
      trap 'release_lock' EXIT
      return 0
    fi
    sleep 1
    (( retry++ ))
  done
  echo "Не удалось получить блокировку" >&2
  return 1
}

release_lock() {
  rm -f "$LOCK_FILE"
}

create_templates() {
  local count=0
  mkdir -p "$WORK_DIR"
  for file in "${!TEMPLATES[@]}"; do
    local target="${WORK_DIR}/${file}"
    [ -f "$target" ] && continue
    echo "${TEMPLATES[$file]}" > "$target" && (( count++ )) || {
      echo "Ошибка создания: ${file}" >&2
    }
  done
  echo $count
}

list_templates() {
  find "$WORK_DIR" -maxdepth 1 -type f -name '*.csv' 2>/dev/null | xargs -n1 basename | sort || {
    echo "Шаблоны не найдены" >&2
    return 1
  }
}

### [КОМАНДЫ] ###
cmd_init() {
  check_termux_env || return 1
  validate_path || return 1
  acquire_lock || return 1
  local created=$(create_templates)
  if (( created > 0 )); then
    echo "Создано ${created} шаблонов в ${WORK_DIR}"
  else
    echo "Все шаблоны уже существуют"
  fi
  if [ -f "${HOME}/bin/notion_log.sh" ]; then
    "${HOME}/bin/notion_log.sh" "init-templates" "success" "Создано ${created} шаблонов"
  fi
}

cmd_list() {
  check_termux_env || return 1
  list_templates
}

cmd_clean() {
  check_termux_env || return 1
  acquire_lock || return 1
  local count=0
  while IFS= read -r file; do
    rm -f "${WORK_DIR}/${file}" && (( count++ ))
  done < <(list_templates)
  echo "Удалено ${count} шаблонов"
  if [ -f "${HOME}/bin/notion_log.sh" ]; then
    "${HOME}/bin/notion_log.sh" "clean-templates" "success" "Удалено ${count} шаблонов"
  fi
}

### [ТОЧКА ВХОДА] ###
main() {
  case "${1:-help}" in
    init)    cmd_init ;;
    list)    cmd_list ;;
    clean)   cmd_clean ;;
    version) echo "Notion Templates Termux v${VERSION}" ;;
    help|*)
      echo "Использование: ${0##*/} [команда]"
      echo "Команды:"
      echo "  init    - Создать шаблоны"
      echo "  list    - Показать шаблоны"
      echo "  clean   - Удалить шаблоны"
      echo "  version - Версия скрипта"
      echo "  help    - Эта справка"
      ;;
  esac
}

main "$@"
