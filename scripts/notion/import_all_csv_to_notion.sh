: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash

CSV_DIR="/storage/emulated/0/Notion_Templates"

# Сопоставление: имя CSV → тип события
declare -A CSV_MAP=(
	["chatend_summary.csv"]="chatend"
	["chatend_insights.csv"]="insight"
	["todo_from_chats.csv"]="task"
	["rules_extracted.csv"]="rule"
	["script_event_log.csv"]="script-event"
)

echo "[INFO] Starting import from CSV → Notion"

for csv_file in "${!CSV_MAP[@]}"; do
	file_path="$CSV_DIR/$csv_file"
	event_type="${CSV_MAP[$csv_file]}"

	if [ -f "$file_path" ]; then
		echo "[+] Importing $csv_file as $event_type..."

		tail -n +2 "$file_path" | while IFS=',' read -r col1 col2 col3 col4 col5 col6; do
			# Можно адаптировать в зависимости от формата CSV
			python3 ~/wheelzone-script-utils/scripts/notion/notion_log_entry.py \
				--title "$col1" \
				--desc "$col2" \
				--type "$event_type" \
				--date "$col5" \
				--status "$col4"
		done

	else
		echo "[-] File not found: $file_path"
	fi
done

echo "[DONE] CSV import to Notion complete."
