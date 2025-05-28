#!/data/data/com.termux/files/usr/bin/bash
SRC=~/wheelzone/bootstrap_tool/Backup
DST=yandex_wheelzone:/lllBackUplll-WheelZone/Backup
rclone copy -v "$SRC" "$DST" --log-file="$SRC/yadisk_push.log"