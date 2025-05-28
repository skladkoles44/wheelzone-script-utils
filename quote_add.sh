#!/data/data/com.termux/files/usr/bin/bash

QUOTE_TEXT="$1"
AUTHOR="${2:-/шеф}"
TAGS="${3:-арх}"

QUOTES_FILE="$HOME/storage/downloads/project_44/Termux/Digest/ai/quotes/quotes.jsonl"

# Генерация UID
UID=$(date +%s | sha1sum | cut -c1-4 | tr a-z A-Z)
ID="${AUTHOR:0:1}${UID}"

# Добавление в файл
echo "{\"id\": \"$ID\", \"text\": \"$QUOTE_TEXT\", \"author\": \"$AUTHOR\", \"tags\": [\"$TAGS\"]}" >> "$QUOTES_FILE"

echo "[✓] Добавлено: $QUOTE_TEXT"
