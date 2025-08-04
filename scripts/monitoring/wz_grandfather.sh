#!/data/data/com.termux/files/usr/bin/bash
# WZ Grandfather Node v1.5 — AI-контроллер мудрец-ворчун на максималках
set -eo pipefail
shopt -s nullglob

readonly LOG_DIR="$HOME/.wz_logs"
readonly NDJSON_LOG="$LOG_DIR/grandfather.ndjson"
readonly RULES_DIR="$HOME/wz-wiki/rules/"
readonly CHATENDS_DIR="$HOME/wz-wiki/WZChatEnds/"
readonly NOTIFY="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh"

mkdir -p "$LOG_DIR"

log_ndjson() {
  local level="$1"
  local message="$2"
  local now
  now="$(date -Iseconds)"
  echo "{\"time\":\"$now\",\"level\":\"$level\",\"module\":\"grandfather\",\"message\":\"$message\"}" >> "$NDJSON_LOG"
}

# === 1. Проверка связей
check_missing_links() {
  for rule in "$RULES_DIR"*.md; do
    local name="$(basename "$rule")"
    grep -q "core" "$rule" || {
      log_ndjson "WARN" "Нет связи с ядром: $name"
      echo "$name — missing core"
    }
    grep -q "chatend" "$rule" || {
      log_ndjson "WARN" "Нет связи с ChatEnd: $name"
      echo "$name — missing ChatEnd"
    }
  done
}

# === 2. Git diff и unstaged check
check_git_status() {
  local output
  output="$(cd ~/wheelzone-script-utils && git status --porcelain)"
  if [ -n "$output" ]; then
    log_ndjson "WARN" "Есть непроиндексированные изменения в wheelzone-script-utils"
  fi
}

# === 3. Советы и подсказки дедули
future_hints() {
  log_ndjson "INFO" "Совет: Добавь wz_notify в каждый monitoring-скрипт"
  log_ndjson "INFO" "Совет: ChatEnd без связанного правила не считается завершённым"
}

# === 4. Отправка в WZ Noiton
send_report_to_notion() {
  if [ -x "$NOTIFY" ]; then
    local message
    message="$(tail -n 10 "$NDJSON_LOG" | jq -r .message | grep . | tail -n 3 | paste -sd '\n' -)"
    "$NOTIFY" --type "core" --title "👴 Grandfather Node ворчит" --message "$message" --permalog || true
  fi
}

# === Запуск
log_ndjson "INFO" "🧓 Запуск дедушки на максималках"
check_missing_links
check_git_status
future_hints
send_report_to_notion
log_ndjson "INFO" "✅ Завершение дедушки"
