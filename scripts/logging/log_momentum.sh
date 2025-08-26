# uuid: 2025-08-26T13:19:27+03:00-3846345970
# title: log_momentum.sh
# component: .
# updated_at: 2025-08-26T13:19:27+03:00


source "$HOME/wheelzone-script-utils/scripts/utils/generate_uuid.sh"
#!/data/data/com.termux/files/usr/bin/bash
# WZ Memory Log: log_momentum.sh v1.0.0

set -euo pipefail
IFS=$'\n\t'

readonly LOGFILE="$HOME/wz-wiki/logs/mnemosyne_log.ndjson"
mkdir -p "$(dirname "$LOGFILE")"

LABEL="${1:-moment}"
MESSAGE="${2:-"Зафиксирован важный момент"}"
TYPE="${3:-turning_point}"
UUID=$($(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py) 2>/dev/null || date +%s%N)

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat >> "$LOGFILE" <<EOF_JSON
{
  "uuid": "$UUID",
  "timestamp": "$TIMESTAMP",
  "label": "$LABEL",
  "type": "$TYPE",
  "thought": "$MESSAGE",
  "source": "user",
  "witness": "gpt",
  "tags": ["memory", "moment", "wheelzone"]
}
EOF_JSON

echo "✅ Momentum '$LABEL' записан в $LOGFILE"
