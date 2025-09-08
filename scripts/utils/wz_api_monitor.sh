#!/usr/bin/env bash
set -euo pipefail
PUB_IP="79.174.85.106"
SCRIPT="$HOME/wheelzone-script-utils/scripts/utils/wz_postdeploy_check.sh"
LOG_DIR="/storage/emulated/0/Download/project_44/Logs"; mkdir -p "$LOG_DIR"

# 1) быстрый smoke (раз в 5 мин)
if [ "${1:-}" = "smoke" ]; then
  "$SCRIPT" "$PUB_IP" >"$LOG_DIR/wz_api_smoke_$(date +%F_%H-%M).log" 2>&1
  exit
fi

# 2) дневной отчёт
if [ "${1:-}" = "daily" ]; then
  OUT="$LOG_DIR/wz_api_daily_$(date +%F).log"
  "$SCRIPT" "$PUB_IP" >"$OUT" 2>&1
  echo "[DAILY] $(date) :: API всё ок ✅" | tee -a "$OUT"
  # отправка в телеграм (пример: curl с токеном/чат-id)
  # curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
  #   -d chat_id="$CHAT_ID" -d text="WZ Daily: API всё ок ✅"
  exit
fi

echo "Usage: $0 [smoke|daily]"
