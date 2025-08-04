#!/data/data/com.termux/files/usr/bin/bash
# WZ Grandfather Node v1.0 — AI-контроллер мудрец-ворчун
set -eo pipefail
shopt -s nullglob

readonly LOG_DIR="$HOME/.wz_logs"
readonly REPORT="$LOG_DIR/grandfather_report_$(date +%Y%m%d_%H%M).log"
readonly RULES_DIR="$HOME/wz-wiki/rules/"
readonly CHATENDS_DIR="$HOME/wz-wiki/WZChatEnds/"
readonly NOTIFY="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh"

echo "[👴] WZ Grandfather Node активирован: $(date)" > "$REPORT"

# === Ворчание по отсутствующим связям ===
check_missing_links() {
  echo "[🧠] Проверка связей между правилами, chatend и core..." >> "$REPORT"

  for rule in "$RULES_DIR"*.md; do
    grep -q "core" "$rule" || echo "[⚠️] Нет связи с ядром: $(basename "$rule")" >> "$REPORT"
    grep -q "chatend" "$rule" || echo "[⚠️] Нет связи с ChatEnd: $(basename "$rule")" >> "$REPORT"
  done
}

# === Future-подсказки дедули ===
future_hints() {
  echo "[🌀] Совет: Добавь связь с wz_notify, чтобы дед мог жаловаться в Notion." >> "$REPORT"
  echo "[🌀] Совет: Проверь, что каждый chatend связан с хотя бы одним правилом." >> "$REPORT"
}

# === Интеграция с wz_notify (если есть)
send_report() {
  if [ -x "$NOTIFY" ]; then
    "$NOTIFY" --type "core" --title "🧓 Grandfather Node Ворчит" --message "$(tail -n 10 "$REPORT")"
  fi
}

check_missing_links
future_hints
send_report

echo "[✅] WZ Grandfather завершил обход в $(date)" >> "$REPORT"
