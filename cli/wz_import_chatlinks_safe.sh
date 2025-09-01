#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:06+03:00-849047695
# title: wz_import_chatlinks_safe.sh
# component: .
# updated_at: 2025-08-26T13:19:06+03:00

set -e

CSV_PATH="$HOME/wzbuffer/Loki_csv_templates/chatlink_map.csv"
LOG_PATH="$HOME/.wzlogs/import_chatlinks.log"
SCRIPT_PATH="$HOME/wheelzone-script-utils/scripts/Loki/wz_import_chatlinks.sh"

echo "[INFO] Запуск надёжного импорта ChatLinks: $(date)" >> "$LOG_PATH"

# Проверка наличия файла
if [[ ! -s "$CSV_PATH" ]]; then
  echo "[ERROR] CSV-файл отсутствует: $CSV_PATH" >> "$LOG_PATH"
  python3 ~/wheelzone-script-utils/scripts/Loki/Loki_log_entry.py \
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
python3 ~/wheelzone-script-utils/scripts/Loki/Loki_log_entry.py \
  --type "script-event" \
  --name "Импорт ChatLinks" \
  --event "import" \
  --source "wz_import_chatlinks_safe.sh" \
  --result "success"
