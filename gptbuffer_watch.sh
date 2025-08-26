#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:04+03:00-1553991701
# title: gptbuffer_watch.sh
# component: .
# updated_at: 2025-08-26T13:20:04+03:00

#WZ_BUFFER_WATCH
#WZ_PID_MANAGED

SCRIPT_NAME="gptbuffer_watch"
PID_FILE="$HOME/storage/shared/project_44/Termux/PIDs/${SCRIPT_NAME}.pid"
LOG_FILE="$HOME/storage/shared/project_44/Termux/Logs/${SCRIPT_NAME}.log"
SOURCE_DIR="/mnt/data"
TARGET_DIR="$HOME/storage/shared/project_44/Termux/Buffer"

# Проверка PID
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "Уже работает с PID $OLD_PID" >> "$LOG_FILE"
        exit 0
    else
        echo "Старый PID найден, но неактивен. Перезапуск..." >> "$LOG_FILE"
        rm "$PID_FILE"
    fi
fi

# Запись PID
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

        # Фильтрация: только нужные типы файлов
        case "$filename" in
            *.md|*.txt|*.sh|*.py|*.json|*.ipynb|*.csv|*.xlsx|*.zip)
                mv "$file" "$TARGET_DIR/" && \
                echo "[$(date)] Перемещено из GPT: $filename" >> "$LOG_FILE"
                ;;
            *) continue ;;
        esac
    done
    sleep 5
done
