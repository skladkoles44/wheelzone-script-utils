#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:29+03:00-1227348623
# title: wz_log_tail.sh
# component: .
# updated_at: 2025-08-26T13:19:29+03:00

# WZ Tail Permalog — просмотр последних логов

PERMALOG="$HOME/wz-wiki/logs/permalog.ndjson"
LINES="${1:-10}"

if [ ! -f "$PERMALOG" ]; then
  echo "⚠️ permalog.ndjson не найден"
  exit 1
fi

tail -n "$LINES" "$PERMALOG" | jq -r '.timestamp + " | " + .type + " | " + .severity + " | " + .title'
