#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:57+03:00-3009264085
# title: downloads_buffer_watch.sh
# component: .
# updated_at: 2025-08-26T13:19:57+03:00

#WZ_BUFFER_WATCH
#WZ_PID_MANAGED

SCRIPT_NAME="downloads_buffer_watch"
PID_FILE="$HOME/storage/shared/project_44/Termux/PIDs/${SCRIPT_NAME}.pid"
LOG_FILE="$HOME/storage/shared/project_44/Termux/Logs/${SCRIPT_NAME}.log"
SOURCE_DIR="$HOME/storage/downloads"
TARGET_DIR="$HOME/storage/shared/project_44/Termux/Buffer"

# Проверка PID
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Watcher уже запущен с PID $OLD_PID" >> "$LOG_FILE"
        exit 0
    else
        echo "Старый PID найден, но не активен. Перезапускаю..." >> "$LOG_FILE"
        rm "$PID_FILE"
    fi
fi

# Запись нового PID
echo $$ > "$PID_FILE"

# Проверка директорий
mkdir -p "$TARGET_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date)] $SCRIPT_NAME запущен" >> "$LOG_FILE"

# Основной цикл
while true; do
    for file in "$SOURCE_DIR"/*; do
        [ -e "$file" ] || continue

        filename=$(basename "$file")
        ext="${filename##*.}"
        now=$(date +%s)
        file_time=$(stat -c %Y "$file" 2>/dev/null)
        age=$((now - file_time))
        size=$(stat -c %s "$file" 2>/dev/null)

        # Фильтры
        case "$ext" in
            md|txt|sh|py|json|ipynb|csv|xlsx|zip) ;;
            *) continue ;;
        esac

        if [[ "$filename" =~ ^(WZ_|GPT_|capsule_|gpt_|backup_) ]]; then
            is_named=1
        else
            is_named=0
        fi

        if [[ "$filename" =~ (Screenshot|Telegram|VID_|IMG_|WhatsApp|Instagram|cache|browser_download) ]]; then
            is_badname=1
        else
            is_badname=0
        fi

        if [ "$age" -le 60 ] && [ "$size" -ge 1024 ] && [ "$size" -le $((50*1024*1024)) ] && [ "$is_named" -eq 1 ] && [ "$is_badname" -eq 0 ]; then
            mv "$file" "$TARGET_DIR/"
            echo "[$(date)] Перемещено: $filename" >> "$LOG_FILE"
        fi
    done
    sleep 5
done

