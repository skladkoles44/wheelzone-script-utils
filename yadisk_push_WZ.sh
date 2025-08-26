#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:20+03:00-3699116489
# title: yadisk_push_WZ.sh
# component: .
# updated_at: 2025-08-26T13:20:20+03:00

SRC=~/wheelzone/bootstrap_tool/Backup
DST=yandex_wheelzone:/lllBackUplll-WheelZone/Backup
rclone copy -v "$SRC" "$DST" --log-file="$SRC/yadisk_push.log"