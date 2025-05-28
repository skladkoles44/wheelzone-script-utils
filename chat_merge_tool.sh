#!/data/data/com.termux/files/usr/bin/bash

# Папки
SRC_DIR=~/storage/downloads
DST_DIR=~/wheelzone/auto-framework/ALL/history
mkdir -p "$DST_DIR"

# Имя итогового файла
timestamp=$(date +"%Y-%m-%d_%H-%M")
outfile="$DST_DIR/chat_merged_$timestamp.md"

# Объединение файлов
find "$SRC_DIR" -type f -iname "*.md" -o -iname "*.txt" | sort | while read file; do
  echo -e "\n\n##### Файл: $(basename "$file")\n" >> "$outfile"
  cat "$file" >> "$outfile"
done

# Удаление дублирующихся строк
awk '!seen[$0]++' "$outfile" > "$outfile.tmp" && mv "$outfile.tmp" "$outfile"

echo "✅ Объединено. Итог: $outfile"
