#!/data/data/com.termux/files/usr/bin/bash
# WZ Log Query v1.1 — фильтрация по полям

set -euo pipefail
IFS=$'\n\t'

LOG_FILE="$HOME/wz-wiki/logs/events.yaml"

TYPE_FILTER=""
SEVERITY_FILTER=""
GREP_OPTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE_FILTER="$2"; shift 2 ;;
    --severity) SEVERITY_FILTER="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[ ! -f "$LOG_FILE" ] && echo "No log file found: $LOG_FILE" && exit 1

[[ -n "$TYPE_FILTER" ]] && GREP_OPTS+=" -A5 \"type: \\\"$TYPE_FILTER\\\"\""
[[ -n "$SEVERITY_FILTER" ]] && GREP_OPTS+=" -A5 \"severity: \\\"$SEVERITY_FILTER\\\"\""

if [[ -z "$GREP_OPTS" ]]; then
  cat "$LOG_FILE"
else
  eval grep $GREP_OPTS "$LOG_FILE"
fi
