#!/data/data/com.termux/files/usr/bin/bash

file="$1"
echo "[gptsync_auto] Получен файл: $file" >> ~/wheelzone/bootstrap_tool/logs/gptsync_auto.log

# Обработка входящих файлов от GPT
bash ~/bin/auto_receive_from_gpt.sh

# Автоматическая распаковка, если архив
if [[ "$file" == *.zip ]]; then
  unzip -o "$file" -d ~/wheelzone/bootstrap_tool/scripts/ >> ~/wheelzone/bootstrap_tool/logs/gptsync_auto.log
  echo "[gptsync_auto] Распакован архив: $file" >> ~/wheelzone/bootstrap_tool/logs/gptsync_auto.log
fi

# Автопуш при необходимости
if [[ "$file" == *.sh || "$file" == *WZ_*.md ]]; then
  bash ~/bin/git_push_WZ_all.sh
fi
