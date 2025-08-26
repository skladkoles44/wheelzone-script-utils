#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:28+03:00-893554999
# title: wz_log_event.sh
# component: .
# updated_at: 2025-08-26T13:19:28+03:00

set -euo pipefail
IFS=$'\n\t'

readonly LOGFILE="$HOME/.wz_logs/permalog.ndjson"
mkdir -p "$(dirname "$LOGFILE")" && touch "$LOGFILE"

TYPE="${1:-event}"
MSG="${2:-"Нет сообщения"}"
SEVERITY="${3:-info}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "{\"timestamp\":\"$TIMESTAMP\",\"type\":\"$TYPE\",\"msg\":\"$MSG\",\"severity\":\"$SEVERITY\"}" >> "$LOGFILE"
echo "✅ [$SEVERITY] $TYPE: $MSG"
