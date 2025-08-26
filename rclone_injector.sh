#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:12+03:00-1649618394
# title: rclone_injector.sh
# component: .
# updated_at: 2025-08-26T13:20:12+03:00

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
