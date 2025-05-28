#!/data/data/com.termux/files/usr/bin/bash

# [WZ] Daily cloud backup via rclone to Yandex.Disk

mkdir -p ~/wheelzone/bootstrap_tool/logs/

echo "[daily_rclone_push] $(date '+%F %T') Start backup" >> ~/wheelzone/bootstrap_tool/logs/rclone_backup.log

rclone copy ~/wheelzone/bootstrap_tool/ yadisk_creator:lllBackUplll-WheelZone \
  --create-empty-src-dirs \
  --log-file ~/wheelzone/bootstrap_tool/logs/rclone_backup.log \
  --log-level INFO

echo "[daily_rclone_push] $(date '+%F %T') Backup finished" >> ~/wheelzone/bootstrap_tool/logs/rclone_backup.log

