#!/data/data/com.termux/files/usr/bin/bash

FILE=~/wheelzone-script-utils/scripts/wz_sync_rules.sh
MARKER='Правило создано:'
LOG_LINE='    notion_log_entry.py --type rule --title "$title" --uuid "$uuid" --file "$file" --created "$created" --source wz_sync_rules.sh'

if grep -q "$MARKER" "$FILE"; then
    echo "✅ Найдено место вставки: $MARKER"
    sed -i "/$MARKER/a\\
$LOG_LINE" "$FILE"
    echo "✅ Вставка выполнена"
else
    echo "❌ Не найдено место вставки: строка с '$MARKER'"
    exit 1
fi
