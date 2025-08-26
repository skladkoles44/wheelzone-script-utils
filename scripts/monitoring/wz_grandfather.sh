#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:30+03:00-2176089025
# title: wz_grandfather.sh
# component: .
# updated_at: 2025-08-26T13:19:30+03:00

# wz_grandfather.sh v1.0 — AI-наблюдатель и ворчун WZ-системы
# Роль: контролирует молчание, активность и запуск ChatEnd

set -euo pipefail
shopt -s nullglob

readonly LOG_DIR="$HOME/.wz_logs"
readonly RUNTIME_LOG="$LOG_DIR/grandfather_tips.log"
readonly OFFLINE_LOG="$LOG_DIR/.wz_offline_log.jsonl"
readonly LAST_ACTIVITY_FILE="$LOG_DIR/.last_wz_activity"
readonly CHATEND_TRIGGER="$HOME/wheelzone-script-utils/scripts/chatend/wz_chatend.sh"
readonly THRESHOLD_MINUTES=180  # Молчание >3 часов — дедушка ругается

mkdir -p "$LOG_DIR"

check_last_activity() {
  if [[ -f "$LAST_ACTIVITY_FILE" ]]; then
    local last_ts=$(stat -c %Y "$LAST_ACTIVITY_FILE")
    local now=$(date +%s)
    local delta=$(( (now - last_ts) / 60 ))

    if (( delta >= THRESHOLD_MINUTES )); then
      echo "[WZ Grandfather] 🧓 Ты что, спишь уже $delta минут? А ну давай, ChatEnd запускай!" >> "$RUNTIME_LOG"
      bash "$CHATEND_TRIGGER" --termux --autolog || echo "[!] ChatEnd запуск не удался" >> "$RUNTIME_LOG"
    else
      echo "[WZ Grandfather] Всё спокойно. Последняя активность: $delta мин назад." >> "$RUNTIME_LOG"
    fi
  else
    echo "[WZ Grandfather] 🧓 Я ещё не знаю, когда ты последний раз шевелился. Сохраняй активность!" >> "$RUNTIME_LOG"
  fi
}

touch "$LAST_ACTIVITY_FILE"
check_last_activity
