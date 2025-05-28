#!/data/data/com.termux/files/usr/bin/bash
HISTORY=~/storage/downloads/project_44/MetaSystem/Logs/wz_command_history.jsonl
LAST=$(tac $HISTORY | grep -m1 '"status": "error"' | jq -r '.content')
if [ -z "$LAST" ]; then
  echo "[wzretry] Нет неудачных команд для повтора."
  exit 0
fi
echo "[wzretry] Повтор команды: $LAST"
eval "$LAST"
NOW=$(date -Iseconds)
ENTRY=$(jq -n --arg cmd "$LAST" --arg now "$NOW" '{
  id: ("RETRY_" + ($now | gsub("[-:]"; "") | gsub("T"; "_"))),
  content: $cmd,
  status: "retried",
  source: "wzretry",
  created_at: $now,
  executed_at: $now
}')
echo "$ENTRY" >> "$HISTORY"
