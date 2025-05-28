#!/data/data/com.termux/files/usr/bin/bash

# Мониторинг папки downloads на предмет новых файлов
inotifywait -m ~/storage/downloads -e create |
while read path action file; do
  echo "[wz_monitor] Обнаружен файл: $file" >> ~/wheelzone/bootstrap_tool/logs/wz_monitor.log

  # Вызов gptsync_auto для любого нового файла
  bash ~/bin/gptsync_auto.sh "$path$file"
done
