#!/data/data/com.termux/files/usr/bin/bash
# WZ Tail Permalog — просмотр последних логов

PERMALOG="$HOME/wz-wiki/logs/permalog.ndjson"
LINES="${1:-10}"

if [ ! -f "$PERMALOG" ]; then
  echo "⚠️ permalog.ndjson не найден"
  exit 1
fi

tail -n "$LINES" "$PERMALOG" | jq -r '.timestamp + " | " + .type + " | " + .severity + " | " + .title'
