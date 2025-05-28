#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:$PATH

# Базовая директория, откуда GPT сбрасывает файлы
INBOX=~/rclone_inbox

# Целевая папка на Яндекс.Диске
REMOTE=yadisk_creator:BackUp

# Логика отправки по подпапкам (чаты = подпапки)
for chat_dir in "$INBOX"/*; do
  if [ -d "$chat_dir" ]; then
    chat_name=$(basename "$chat_dir")
    echo "Отправка из чата: $chat_name → $REMOTE/$chat_name"
    rclone copy "$chat_dir" "$REMOTE/$chat_name" --create-empty-src-dirs --progress
  fi
done
