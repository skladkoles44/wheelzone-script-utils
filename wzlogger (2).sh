#!/data/data/com.termux/files/usr/bin/bash
HISTORY=~/storage/downloads/project_44/MetaSystem/Logs/wz_command_history.jsonl

CMD="$1"
if [ -z "$CMD" ]; then
  echo "[wzlogger] Использование: wzlogger '<команда>'"
  exit 1
fi

NOW=$(date -Iseconds)
UUID="CMD_$(echo $NOW | tr -d ':T.-')"

echo "{ \"id\": \"$UUID\", \"content\": \"$CMD\", \"status\": \"success\", \"source\": \"manual\", \"created_at\": \"$NOW\", \"executed_at\": \"$NOW\" }" >> $HISTORY
echo "[wzlogger] Записано: $CMD"
