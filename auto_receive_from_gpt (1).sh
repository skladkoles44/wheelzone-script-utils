#!/data/data/com.termux/files/usr/bin/bash

cd ~/storage/downloads
for file in /mnt/data/*.sh /mnt/data/*.zip; do
  [ -e "$file" ] || continue
  cp "$file" .
  chmod +x "$(basename "$file")" 2>/dev/null
  echo "[auto_receive_from_gpt] Получен: $(basename "$file")" >> ~/wheelzone/bootstrap_tool/logs/gpt_receive.log
done
