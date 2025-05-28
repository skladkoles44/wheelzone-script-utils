# --- ВСТАВИТЬ ПЕРЕД ФОРМИРОВАНИЕМ DIGEST-ФАЙЛА ---

LMS_LOG="$HOME/wheelzone/wheelzone-core/personas/shef/roadmap/knowledge/lms_log.jsonl"
LMS_ENTRY=$(tail -n 1 "$LMS_LOG")

LMS_ID=$(echo "$LMS_ENTRY" | jq -r '.id')
LMS_TEXT=$(echo "$LMS_ENTRY" | jq -r '.text')
LMS_AUTHOR=$(echo "$LMS_ENTRY" | jq -r '.author')

LMS_BLOCK="📚 Урок от ${LMS_AUTHOR}\n\n${LMS_TEXT}\n\nUID: ${LMS_ID}"

# --- И потом ДОБАВИТЬ ЭТО В ФАЙЛ DIGEST ---
echo -e "\n\n${LMS_BLOCK}" >> "$DIGEST_FILE"#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash

TOKEN="7593126254:AAG61-IsOp1H-MaZcGVc2jRBm8WrXMmkYFA"
CHAT_ID="-1002654013714"
TODAY=$(date +"%Y-%m-%d")
DIGEST_FILE="$HOME/storage/downloads/project_44/Termux/Digest/daily_digest_${TODAY}.md"
DIGEST_DIR="$HOME/storage/downloads/project_44/Termux/Digest"

mkdir -p "$DIGEST_DIR"

{
  echo "# Daily Digest — $TODAY"
  echo ""
  echo "## Events"
  find "$DIGEST_DIR/incidents/" -type f -name "*$TODAY*.md" -exec cat {} + 2>/dev/null || echo "- No events"
  echo ""
  echo "## Lessons Learned"
  find "$DIGEST_DIR/lessons/" -type f -name "*$TODAY*.md" -exec cat {} + 2>/dev/null || echo "- No lessons"
  echo ""
  echo "## Vaccinations"
  find "$DIGEST_DIR/vaccinations/" -type f -name "*$TODAY*.md" -exec cat {} + 2>/dev/null || echo "- No vaccinations"
} > "$DIGEST_FILE"

curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" \
  -F chat_id="$CHAT_ID" \
  -F document=@"$DIGEST_FILE"
QUOTE_FILE="$HOME/storage/downloads/project_44/Termux/Digest/ai/chef_quotes.md"
QUOTE=$(shuf -n 1 "$QUOTE_FILE" 2>/dev/null)

QUOTE_JSON=$(bash ~/storage/downloads/project_44/Termux/Script/quote_picker.sh)
QUOTE_TEXT=$(echo "$QUOTE_JSON" | jq -r '.text')
QUOTE_AUTHOR=$(echo "$QUOTE_JSON" | jq -r '.author')
QUOTE_ID=$(echo "$QUOTE_JSON" | jq -r '.id')
QUOTE_TAGS=$(echo "$QUOTE_JSON" | jq -r '.tags | join(", ")')

if [ -n "$QUOTE_TEXT" ] && [ "$QUOTE_TEXT" != "null" ]; then
  {
    echo -e "\n---"
    echo "## Что бы сказал $QUOTE_AUTHOR:"
    echo "- $QUOTE_TEXT"
    echo ""
    echo "_Цитата: $QUOTE_ID | Теги: $QUOTE_TAGS_"
    echo "@daily_quotes"
  } >> "$DIGEST_FILE"
fi
# 🧠 Добавление урока от /шеф
LMS_LOG="$HOME/wheelzone/wheelzone-core/personas/shef/roadmap/knowledge/lms_log.jsonl"
if [ -f "$LMS_LOG" ]; then
  LMS_ENTRY=$(tail -n 1 "$LMS_LOG")
  LMS_ID=$(echo "$LMS_ENTRY" | jq -r '.id')
  LMS_TEXT=$(echo "$LMS_ENTRY" | jq -r '.text')
  LMS_AUTHOR=$(echo "$LMS_ENTRY" | jq -r '.author')
  echo -e "\n\n📚 Урок от ${LMS_AUTHOR}\n\n${LMS_TEXT}\n\nUID: ${LMS_ID}" >> "$DIGEST_FILE"
fi
echo "[✓] Digest отправлен: $DIGEST_FILE"
# Автосохранение цитаты и Digest в Git
cd ~/wheelzone/wheelzone-phrases
git pull --quiet
git add quotes/used_quotes.jsonl
git commit -m "used quote $(date +%F)"
git push --quiet
