#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:31+03:00-1928966014
# title: wz_offline_replay.sh
# component: .
# updated_at: 2025-08-26T13:19:31+03:00

# wz_offline_replay.sh v1.0.0 — воспроизведение offline логов из ~/.wz_offline_log.jsonl

OFFLINE_LOG="${HOME}/.wz_offline_log.jsonl"
TMP_FILE="$(mktemp)"
LOGGER_PY="$HOME/wheelzone-script-utils/scripts/notion/notion_log_entry.py"

[[ ! -f "$OFFLINE_LOG" ]] && echo "✅ Нет накопленных логов для отправки" && exit 0
[[ ! -f "$LOGGER_PY" ]] && echo "❌ Не найден логгер: $LOGGER_PY" && exit 1

cat "$OFFLINE_LOG" > "$TMP_FILE"
> "$OFFLINE_LOG"

while read -r LINE; do
  EVENT=$(echo "$LINE" | jq -r '.event')
  ARGS=$(echo "$LINE" | jq -r '.args | @sh')
  eval python3 "$LOGGER_PY" --event "$EVENT" $ARGS
  [[ $? -ne 0 ]] && echo "$LINE" >> "$OFFLINE_LOG"
done < "$TMP_FILE"

rm -f "$TMP_FILE"
