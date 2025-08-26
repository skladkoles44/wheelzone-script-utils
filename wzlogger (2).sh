#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:19+03:00-440725556
# title: wzlogger (2).sh
# component: .
# updated_at: 2025-08-26T13:20:19+03:00

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
