#!/data/data/com.termux/files/usr/bin/bash

# ================================================
# 🚀 PERMALOG ULTIMATE INTEGRATION (v3.1)
# Улучшения для Termux/Android 15/HyperOS
# ================================================

set -euo pipefail
IFS=$'\n\t'

{
  readonly TMPDIR="${HOME}/.cache/permalog"
  mkdir -p "${TMPDIR}" || {
    echo "Не удалось создать временный каталог" >&2
    exit 1
  }

  ulimit -s 8192 2>/dev/null || true

  log() {
    local msg="$1"
    echo "[PERMALOG][$(date '+%Y-%m-%d %H:%M:%S')] ${msg}" >> "${TMPDIR}/permalog_install.log"
  }

  declare -A deps=(
    ["ts"]="moreutils"
    ["parallel"]="parallel"
    ["jq"]="jq"
  )

  log "Проверка зависимостей..."
  for cmd in "${!deps[@]}"; do
    if ! command -v "${cmd}" &>/dev/null; then
      log "Установка ${deps[$cmd]}..."
      if ! pkg install -y "${deps[$cmd]}" >/dev/null 2>&1; then
        log "Ошибка установки ${deps[$cmd]}" >&2
        exit 1
      fi
    fi
  done

  permalog_patch() {
    local file="$1"
    [[ -f "${file}" ]] || return 1

    local marker="# PERMALOGv3_$(date +%s)"
    if grep -q "${marker}" "${file}"; then
      log "Пропускаем (уже обновлён): ${file}"
      return 0
    fi

    local tmpfile="${file}.tmp"
    if sed "/wz_notify\.sh/ {
      s|$| --permalog|
      a ${marker}
    }" "${file}" > "${tmpfile}"; then
      mv "${tmpfile}" "${file}"
      log "Обновлён: ${file}"
      return 0
    else
      rm -f "${tmpfile}" 2>/dev/null
      return 1
    fi
  }

  export -f permalog_patch
  export -f log

  declare -a script_paths=(
    ~/wheelzone-script-utils/scripts/wz_chatend.sh
    ~/wheelzone-script-utils/scripts/ci/wzdrone_chatend.sh
    ~/wheelzone-script-utils/scripts/utils/wz_ai_rule.sh
    ~/wheelzone-script-utils/scripts/notion/wz_notify.sh
    ~/wheelzone-script-utils/scripts/notion/sync_chatend_to_notion.sh
    ~/wheelzone-script-utils/scripts/notion/register_notion_tools.sh
  )

  log "Начинаем параллельное обновление..."
  printf "%s\n" "${script_paths[@]}" | \
    parallel -j 4 --bar --progress 'permalog_patch {}' 2>> "${TMPDIR}/permalog_install.err"

  git_commit() {
    local repo="$1"
    [[ -d "${repo}/.git" ]] || return

    (
      cd "${repo}" || exit 1
      if git diff --quiet --exit-code && git diff --cached --quiet --exit-code; then
        log "Нет изменений в $(basename "${repo}")"
        return
      fi

      if git add . && \
         git commit -m "feat: auto-permalog v3.1 $(date +%Y%m%d)" && \
         git push origin master; then
        log "Успешный пуш в $(basename "${repo}")"
      else
        log "Ошибка push в $(basename "${repo}")" >&2
      fi
    )
  }

  git_commit ~/wheelzone-script-utils
  git_commit ~/wz-wiki

  check_health() {
    local error=0
    local logfile="${HOME}/wheelzone-script-utils/logs/permalog.log"

    mkdir -p "$(dirname "${logfile}")"
    touch "${logfile}"
    chmod 600 "${logfile}"

    for script in "${script_paths[@]}"; do
      if [[ ! -f "${script}" ]]; then
        ((error++))
        log "Отсутствует скрипт: ${script}"
      fi
    done

    (( error == 0 )) && log "Все скрипты верифицированы" || log "Найдены ${error} проблем"
  }

  check_health

  notify() {
    local count
    count=$(find "${script_paths[@]}" -type f 2>/dev/null | wc -l)
    local msg="✅ Permalog v3.1 установлен\nОбновлено: ${count} скриптов"

    if command -v termux-notification &>/dev/null; then
      termux-notification \
        --title "Permalog Ultimate" \
        --content "${msg}" \
        --icon done
    fi
  }

  notify

report="
e[1;34m=== ИТОГОВЫЙ ОТЧЁТ ===e[0m
ЛОГИ:         ${TMPDIR}/permalog_install.log
ОШИБКИ:       ${TMPDIR}/permalog_install.err
СКРИПТОВ:     $(find "${script_paths[@]}" -type f 2>/dev/null | wc -l)
ЗАПИСЕЙ:      $(wc -l < "${HOME}/wheelzone-script-utils/logs/permalog.log" 2>/dev/null || echo 0)"

echo -e "$report" | tee -a "${TMPDIR}/permalog_install.log"

} > >(tee -a "${TMPDIR}/permalog_install.log") 2> >(tee -a "${TMPDIR}/permalog_install.err" >&2)

echo -e "\n\e[1m=== ИТОГОВЫЙ ОТЧЁТ ===\e[0m"
column -t -s '|' <<EOF_REPORT
\e[34mЛОГИ:|${TMPDIR}/permalog_install.log
ОШИБКИ:|${TMPDIR}/permalog_install.err
СКРИПТОВ:|$(find "${script_paths[@]}" -type f 2>/dev/null | wc -l)
ЗАПИСЕЙ:|$(wc -l < "${HOME}/wheelzone-script-utils/logs/permalog.log" 2>/dev/null || echo 0)\e[0m
EOF_REPORT
