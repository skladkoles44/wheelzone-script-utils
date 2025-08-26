#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-2107550204
# title: verlog.sh
# component: .
# updated_at: 2025-08-26T13:20:17+03:00

file=$1
if [ -z "$file" ]; then echo "Укажи имя файла"; exit 1; fi
grep "$file" file_versions_index.json || echo "Нет версий в индексе"
