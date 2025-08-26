#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:20+03:00-346718993
# title: wzresolve (1).sh
# component: .
# updated_at: 2025-08-26T13:20:20+03:00

QUESTIONS=~/storage/downloads/project_44/MetaSystem/Logs/wz_open_questions.jsonl
RESOLVED=~/storage/downloads/project_44/MetaSystem/Logs/wz_resolved.jsonl

if [ $# -lt 2 ]; then
  echo "Использование: wzresolve <ID> <комментарий>"
  exit 1
fi

ID=$1
shift
COMMENT=$@

if ! grep -q "$ID" "$QUESTIONS"; then
  echo "[wzresolve] Вопрос с ID '$ID' не найден среди открытых."
  exit 1
fi

# Извлечём строку, добавим поля resolved и log
QUESTION=$(grep "$ID" "$QUESTIONS" | head -n1)
RESOLVED_QUESTION=$(echo "$QUESTION" | jq --arg id "$ID" --arg comment "$COMMENT" --arg now "$(date -Iseconds)" '. + {
  status: "resolved",
  resolved_at: $now,
  resolution: $comment
}')

# Запишем в архив
echo "$RESOLVED_QUESTION" >> "$RESOLVED"

# Удалим из активных
grep -v "$ID" "$QUESTIONS" > "$QUESTIONS.tmp" && mv "$QUESTIONS.tmp" "$QUESTIONS"

echo "[wzresolve] Вопрос $ID помечен как решён."
