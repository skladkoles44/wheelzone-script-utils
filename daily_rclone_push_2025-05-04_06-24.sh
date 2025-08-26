#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:55+03:00-1369324509
# title: daily_rclone_push_2025-05-04_06-24.sh
# component: .
# updated_at: 2025-08-26T13:19:55+03:00

# [Yadisk Backup] Пуш в папку lllBackUplll-WheelZone
echo "[2025-05-04 06:24:31] Start backup to Yandex.Disk"

rclone copy ~/wheelzone/bootstrap_tool yadisk_creator:lllBackUplll-WheelZone \
  --create-empty-src-dirs \
  --progress \
  --log-file=~/wheelzone/bootstrap_tool/logs/rclone_backup.log \
  --log-level INFO

echo "[2025-05-04 06:24:31] Backup complete"
