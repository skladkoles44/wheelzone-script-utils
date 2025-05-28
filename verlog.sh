#!/data/data/com.termux/files/usr/bin/bash
file=$1
if [ -z "$file" ]; then echo "Укажи имя файла"; exit 1; fi
grep "$file" file_versions_index.json || echo "Нет версий в индексе"
