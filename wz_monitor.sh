#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-2294702495
# title: wz_monitor.sh
# component: .
# updated_at: 2025-08-26T13:20:18+03:00


# Мониторинг папки downloads на предмет новых файлов
inotifywait -m ~/storage/downloads -e create |
while read path action file; do
  echo "[wz_monitor] Обнаружен файл: $file" >> ~/wheelzone/bootstrap_tool/logs/wz_monitor.log

  # Вызов gptsync_auto для любого нового файла
  bash ~/bin/gptsync_auto.sh "$path$file"
done
