#!/data/data/com.termux/files/usr/bin/bash

QUOTES_FILE="$HOME/storage/downloads/project_44/Termux/Digest/ai/quotes/quotes.jsonl"

if [ ! -f "$QUOTES_FILE" ]; then
  echo "❌ Файл цитат не найден."
  exit 1
fi

cat "$QUOTES_FILE" | jq -r '[.id, .author, .text] | "[

