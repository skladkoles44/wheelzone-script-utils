#!/data/data/com.termux/files/usr/bin/bash

DIGEST_DIR="$HOME/wheelzone/wheelzone-core/personas/shef"
DATE=$(date +%F)
OUTFILE="$DIGEST_DIR/digest_$DATE.md"
LOGFILE="$DIGEST_DIR/digest_log.jsonl"

echo "# 🧠 Ежедневный отчёт от /шеф ($DATE)" > "$OUTFILE"
echo >> "$OUTFILE"

echo "## События, наблюдения, паттерны:" >> "$OUTFILE"
echo "- Подключена личность /шеф" >> "$OUTFILE"
echo "- Самообучение включено" >> "$OUTFILE"
echo "- Работа в фоне активна" >> "$OUTFILE"
echo >> "$OUTFILE"

echo "{\"date\":\"$DATE\",\"status\":\"ok\",\"file\":\"$OUTFILE\"}" >> "$LOGFILE"#!/data/data/com.termux/files/usr/bin/bash

# [2025-05-28 09:39] Скрипт создан через newscript()
