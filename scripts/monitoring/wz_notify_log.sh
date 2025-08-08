#!/usr/bin/env bash
# wz_notify_log.sh v1.0.0 — безопасный логер для событий WheelZone

EVENT="$1"
shift

ARGS=("$@")
FALLBACK_LOG="${HOME}/.wz_offline_log.jsonl"
LOGGER_PY="$HOME/wheelzone-script-utils/scripts/notion/notion_log_entry.py"

if [[ ! -f "$LOGGER_PY" ]]; then
  echo "❌ Не найден логгер: $LOGGER_PY"
  exit 1
fi

python3 "$LOGGER_PY" --event "$EVENT" "${ARGS[@]}" --verbose 2>/dev/null
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
  TIMESTAMP=$(date -Iseconds)
  PAYLOAD=$(jq -n --arg event "$EVENT" --argjson args "$(printf '%s\n' "${ARGS[@]}" | jq -R . | jq -s .)" \
    '{timestamp: $TIMESTAMP, event: $event, args: $args}')
  echo "$PAYLOAD" >> "$FALLBACK_LOG"
  echo "⚠️ Записано в fallback: $FALLBACK_LOG"
fi
