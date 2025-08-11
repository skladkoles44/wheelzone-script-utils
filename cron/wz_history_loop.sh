#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
LOG="$HOME/.wz_logs/wz_history_loop.log"
mkdir -p "$(dirname "$LOG")"
echo "[START] $(date -u +"%F %T") loop" >> "$LOG"
while true; do
  ts="$(date -u +"%F %T")"
  echo "[$ts] fix_headers..." >> "$LOG"
  bash "$HOME/wheelzone-script-utils/scripts/utils/wz_history_fix_headers.sh" >> "$LOG" 2>&1 || echo "[$ts] fix_headers: warn" >> "$LOG"
  echo "[$ts] backup..." >> "$LOG"
  bash "$HOME/wheelzone-script-utils/cron/wz_history_backup.sh" >> "$LOG" 2>&1 || echo "[$ts] backup: warn" >> "$LOG"
  echo "[$ts] sleep 6h" >> "$LOG"
  sleep 21600
done
