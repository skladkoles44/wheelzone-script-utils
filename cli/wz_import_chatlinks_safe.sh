#!/data/data/com.termux/files/usr/bin/bash
set -e

CSV_PATH="$HOME/wzbuffer/notion_csv_templates/chatlink_map.csv"
LOG_PATH="$HOME/.wzlogs/import_chatlinks.log"
SCRIPT_PATH="$HOME/wheelzone-script-utils/scripts/notion/wz_import_chatlinks.sh"

echo "[INFO] Запуск надёжного импорта ChatLinks: $(date)" >> "$LOG_PATH"

# Проверка наличия файла
if [[ ! -s "$CSV_PATH" ]]; then
  echo "[ERROR] CSV-файл отсутствует: $CSV_PATH" >> "$LOG_PATH"
  python3 ~/wheelzone-script-utils/scripts/notion/notion_log_entry.py \
    --type "script-event" \
    --name "Импорт ChatLinks" \
    --event "import" \
    --source "wz_import_chatlinks_safe.sh" \
    --result "fail"
  exit 1
fi

# Запуск основного скрипта
bash "$SCRIPT_PATH" >> "$LOG_PATH" 2>&1

# Успешный лог
python3 ~/wheelzone-script-utils/scripts/notion/notion_log_entry.py \
  --type "script-event" \
  --name "Импорт ChatLinks" \
  --event "import" \
  --source "wz_import_chatlinks_safe.sh" \
  --result "success"
