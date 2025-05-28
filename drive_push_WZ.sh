#!/data/data/com.termux/files/usr/bin/bash
SRC=~/wheelzone/bootstrap_tool/Backup
DST=gdrive:/lllBackUplll-WheelZone/Backup
rclone copy -v "$SRC" "$DST" --log-file="$SRC/drive_push.log"