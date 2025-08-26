#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:41+03:00-498044226
# title: trim_fractal_log.sh
# component: .
# updated_at: 2025-08-26T13:19:41+03:00

set -Eeuo pipefail
LOG="${1:-$HOME/.wz_logs/fractal_chatend.log}"
MAX="${2:-5000}"
[ -f "$LOG" ] || { echo "[=] no log"; exit 0; }
LINES=$(wc -l < "$LOG" || echo 0)
if [ "$LINES" -gt "$MAX" ]; then
  tail -n "$MAX" "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"
  echo "[i] trimmed $LOG to $MAX lines"
else
  echo "[=] no trim ($LINES <= $MAX)"
fi
