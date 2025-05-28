#!/data/data/com.termux/files/usr/bin/bash
QUESTIONS=~/storage/downloads/project_44/MetaSystem/Logs/wz_open_questions.jsonl

if [ ! -f "$QUESTIONS" ]; then
  echo "[wzq] Вопросов нет. Файл не найден: $QUESTIONS"
  exit 0
fi

echo "[wzq] Актуальные незакрытые вопросы:"
if [ "$1" == "--all" ]; then
  grep '"status": "open"' "$QUESTIONS" | jq -s '.[] | {id, question, severity, created_at}'
else
  grep '"status": "open"' "$QUESTIONS" | jq -s '.[-5:][] | {id, question, severity, created_at}'
fi
