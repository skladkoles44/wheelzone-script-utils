#!/data/data/com.termux/files/usr/bin/bash
# WZ Notify v2.2.3 — Фрактальный Termux-Notion wrapper
# ░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀░█░█
# ░█▀▀░█░█░█░█░█▀▀░░█░░█░█░█▀█
# ░▀░░░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀░▀░▀

# === Фрактал Core ===
fractalize() {
  local func_name="$1"
  shift
  echo "┌── ${func_name}($*)" >> "${TRACE_LOG}"
  "${func_name}" "$@" | tee -a "${DEBUG_LOG}"  # Самоподобие вывода
  echo "└── ${func_name}($*) → $?" >> "${TRACE_LOG}"
}

# === Фрактал инициализации ===
init_fractal() {
  set -euo pipefail
  IFS=$'\n\t'
  readonly SCRIPT_NAME="${0##*/}"
  readonly ENV_FILE="$HOME/.env.wzbot"
  readonly WZ_HOME="$HOME/wheelzone-script-utils"
  readonly LOGDIR="$HOME/.local/var/log"
  mkdir -p "${LOGDIR}" "${WZ_HOME}/logs"

  # Фрактальные логи (NDJSON + дерево вызовов)
  readonly DEBUG_LOG="${LOGDIR}/wz_notify_debug.ndjson"
  readonly TRACE_LOG="${LOGDIR}/wz_notify_trace.fractal"
  exec 2>> "${TRACE_LOG}"  # Автоматическое логирование ошибок
}

# === Фрактал логирования ===
log_fractal() {
  local level="$1" msg="$2"
  fractalize log_internal "${level}" "${msg}"  # Рекурсивный вызов
}

log_internal() {
  jq -cn --arg lvl "$1" --arg msg "$2" \
    '{time: (now|todateiso8601), level: $lvl, message: $msg}' \
    >> "${DEBUG_LOG}"
}

# === Фрактал аргументов ===
parse_fractal() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stdin)
        fractalize process_stdin
        ;;
      --selftest)
        fractalize run_selftest
        exit 0
        ;;
      *) 
        log_fractal "ERROR" "Неизвестный аргумент: $1"
        exit 1
        ;;
    esac
    shift
  done
}

process_stdin() {
  [[ -t 0 ]] && { log_fractal "ERROR" "--stdin given but stdin empty"; exit 1; }
  jq -c '.' < /dev/stdin > "${LOGDIR}/tmp_notify_input.json"
  log_fractal "DEBUG" "Сохранён stdin"
}

run_selftest() {
  log_fractal "INFO" "Запуск фрактального теста"
  echo '{"type":"system","title":"🔧 Фрактальный вызов","message":"Рекурсия успешна!","severity":"info"}' \
    | fractalize parse_fractal --stdin
}

# === Главный фрактал ===
main() {
  init_fractal
  log_fractal "INFO" "Запуск ${SCRIPT_NAME} (PID $$)"
  fractalize parse_fractal "$@"
  log_fractal "INFO" "Завершение работы"
}

main "$@"  # Запуск фрактальной вселенной
