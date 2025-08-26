#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:49+03:00-1331935070
# title: auto_receive_from_gpt (1).sh
# component: .
# updated_at: 2025-08-26T13:19:50+03:00


cd ~/storage/downloads
for file in /mnt/data/*.sh /mnt/data/*.zip; do
  [ -e "$file" ] || continue
  cp "$file" .
  chmod +x "$(basename "$file")" 2>/dev/null
  echo "[auto_receive_from_gpt] Получен: $(basename "$file")" >> ~/wheelzone/bootstrap_tool/logs/gpt_receive.log
done
