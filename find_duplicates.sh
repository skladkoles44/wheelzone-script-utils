#!/data/data/com.termux/files/usr/bin/bash
# Поиск дубликатов файлов по хешу во всех папках Termux-хранилища

BASE="$HOME"
LOG="/data/data/com.termux/files/home/wheelzone/bootstrap_tool/ALL/duplicate_report_2025-05-06_07-35.txt"
TMP="/data/data/com.termux/files/usr/tmp/dup_hashes.txt"

echo "[START] Поиск дубликатов — $(date)" > "$LOG"

find "$BASE" -type f -exec sha1sum {} + 2>/dev/null | sort > "$TMP"
cut -d ' ' -f 1 "$TMP" | uniq -d | while read hash; do
  echo "Дубликаты хеша $hash:" >> "$LOG"
  grep "^$hash" "$TMP" | cut -d ' ' -f 3- >> "$LOG"
  echo "——" >> "$LOG"
done

rm "$TMP"
echo "[DONE] Отчёт сохранён в: $LOG"
