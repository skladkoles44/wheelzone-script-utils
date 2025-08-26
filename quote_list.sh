#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:12+03:00-3361154088
# title: quote_list.sh
# component: .
# updated_at: 2025-08-26T13:20:12+03:00


QUOTES_FILE="$HOME/storage/downloads/project_44/Termux/Digest/ai/quotes/quotes.jsonl"

if [ ! -f "$QUOTES_FILE" ]; then
  echo "❌ Файл цитат не найден."
  exit 1
fi

cat "$QUOTES_FILE" | jq -r '[.id, .author, .text] | "[

