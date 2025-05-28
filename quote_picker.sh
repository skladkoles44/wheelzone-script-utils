#!/data/data/com.termux/files/usr/bin/bash
# Определяем тему дня
DOW=$(date +%u)
case "$DOW" in
  1) TOPIC="арх" ;;  # Пн
  2) TOPIC="контр" ;;
  3) TOPIC="техно" ;;
  4) TOPIC="арх" ;;
  5) TOPIC="контр" ;;
  6) TOPIC="техно" ;;
  7) TOPIC="арх" ;;  # Вс
esac
QUOTES="$HOME/storage/downloads/project_44/Termux/Digest/ai/quotes/quotes.jsonl"
USED="$HOME/storage/downloads/project_44/Termux/Digest/ai/quotes/used_quotes.jsonl"

mkdir -p "$(dirname "$USED")"
touch "$USED"

# Отбор неиспользованных цитат
QUOTE=$(jq --arg tag "$TOPIC" -c 'select(.tags | index($tag))' "$QUOTES" | grep -vxFf "$USED" | shuf -n 1)

# fallback
if [ -z "$QUOTE" ]; then
  QUOTE=$(grep -vxFf "$USED" "$QUOTES" | shuf -n 1)
fi
