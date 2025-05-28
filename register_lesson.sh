#!/data/data/com.termux/files/usr/bin/bash

LESSON="$*"
DATE=$(date +"%Y-%m-%d")
DIR="$HOME/storage/downloads/project_44/Termux/Digest/lessons"
mkdir -p "$DIR"
FILENAME="$DIR/${DATE}_lesson.md"

echo "## Lesson Learned — $DATE" > "$FILENAME"
echo "$LESSON" >> "$FILENAME"
echo "[✓] Урок сохранён: $FILENAME"
#!/data/data/com.termux/files/usr/bin/bash

# [2025-05-27 23:55] Скрипт создан через newscript()
