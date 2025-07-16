#!/data/data/com.termux/files/usr/bin/bash  
# WBP v2.7.4 — Абсолютно надёжный валидатор (Termux/HyperOS)  
  
CONFIG_DIR="${HOME}/wheelzone-script-utils"  
POLICY_FILE="${CONFIG_DIR}/configs/WZViolationPolicy.yaml"  
LOG_FILE="${CONFIG_DIR}/logs/violations.log"  
CACHE_FILE="$(mktemp -u "${PREFIX}"/tmp/wbp_cache.XXXXXX)"  
  
declare -A REPLACEMENTS=(  
  ["я закоммитил"]="изменения зафиксированы"  
  ["форсил пуш"]="выполнен принудительный push"  
  ["взлом[а-я]*"]="обнаружена уязвимость"  
  ["украл"]="получен доступ"  
  ["эксплойт"]="использование уязвимости"  
  ["рофлил"]="проанализировано"  
  ["крашнул"]="вызван сбой"  
  ["я (сделал|добавил|исправил)"]="рекомендуется"  
  ["(сделано|добавлено) мной"]="предлагается"  
)  
  
safe_log() {  
  local message="$1"  
  local log_dir="$(dirname "${LOG_FILE}")"  
    
  mkdir -p "${log_dir}" || return 1  
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}" >> "${LOG_FILE}" 2>/dev/null || return 1  
  
  if [ "$(stat -c %s "${LOG_FILE}" 2>/dev/null || echo 0)" -gt 1048576 ]; then  
    mv "${LOG_FILE}" "${LOG_FILE}.old" 2>/dev/null  
    gzip -f "${LOG_FILE}.old" 2>/dev/null  
    echo "[Лог ротирован]" > "${LOG_FILE}"  
  fi  
  
  if [ -t 0 ] && [ -t 1 ] && command -v termux-notification >/dev/null; then  
    termux-notification -t "WBP Alert" -c "${message}" 2>/dev/null  
  fi  
}  
  
validate_yaml() {  
  [ -f "${POLICY_FILE}" ] && grep -qm1 "forbidden_phrases:" "${POLICY_FILE}"  
}  
  
load_rules() {  
  {  
    for phrase in "${!REPLACEMENTS[@]}"; do  
      printf '%s=%s\n' "${phrase}" "${REPLACEMENTS[${phrase}]}"  
    done  
  
    if validate_yaml; then  
      grep -A100 "forbidden_phrases:" "${POLICY_FILE}" |   
        grep -E "^- " |   
        sed 's/^- //; s/"//g; s/.*/&=REDACTED/'  
    fi  
  } > "${CACHE_FILE}" 2>/dev/null  
}  
  
safe_process() {  
  local text="$1"  
  local tmp_file="$(mktemp -u "${PREFIX}"/tmp/wbp_text.XXXXXX)"  
  
  printf '%s' "${text}" > "${tmp_file}"  
    
  awk -F= -v changed=0 '  
    NR==FNR { rules[$1]=$2; next }  
    {  
      for (r in rules) {  
        if (match(tolower($0), r)) {  
          gsub(r, rules[r], $0)  
          changed=1  
        }  
      }  
      print  
    }  
    END { exit (changed ? 1 : 0) }  
  ' "${CACHE_FILE}" "${tmp_file}" 2>/dev/null  
  
  local result=$?  
  rm -f "${tmp_file}" 2>/dev/null  
  return ${result}  
}  
  
main() {  
  mkdir -p "${CONFIG_DIR}/configs" "${CONFIG_DIR}/logs" 2>/dev/null  
  
  if [ -t 0 ]; then  
    echo "Использование: echo 'текст' | $0" >&2  
    exit 1  
  fi  
  
  local input=""  
  if ! input="$(cat 2>/dev/null)"; then  
    safe_log "Ошибка чтения ввода"  
    exit 1  
  fi  
  
  if [ -z "${input}" ]; then  
    safe_log "Пустой ввод"  
    exit 1  
  fi  
  
  if ! load_rules; then  
    safe_log "Ошибка загрузки правил"  
    exit 1  
  fi  
  
  if ! safe_process "${input}"; then  
    safe_log "Нарушения исправлены"  
    exit 1  
  fi  
}  
  
trap 'rm -f "${CACHE_FILE}" 2>/dev/null' EXIT  
main "$@"  
