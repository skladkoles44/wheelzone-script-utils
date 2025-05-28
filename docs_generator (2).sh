#!/data/data/com.termux/files/usr/bin/bash
DOC=~/storage/downloads/project_44/MetaSystem/docs_index.md
echo "# Index of Documentation Files" > "$DOC"
echo "" >> "$DOC"
find ~/storage/downloads/project_44/ -type f \( -name '*.md' -o -name '*.sh' -o -name '*.jsonl' \) | while read -r file; do
  echo "- \`${file##*/}\` — $(head -n 1 "$file" | cut -c1-100)" >> "$DOC"
done
echo "[docs_generator] Сформирован $DOC"
