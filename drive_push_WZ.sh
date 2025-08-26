#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:57+03:00-2151784116
# title: drive_push_WZ.sh
# component: .
# updated_at: 2025-08-26T13:19:57+03:00

SRC=~/wheelzone/bootstrap_tool/Backup
DST=gdrive:/lllBackUplll-WheelZone/Backup
rclone copy -v "$SRC" "$DST" --log-file="$SRC/drive_push.log"