#!/bin/bash
# uuid: 2025-08-26T13:20:11+03:00-2124882870
# title: push_to_drive.sh
# component: .
# updated_at: 2025-08-26T13:20:11+03:00


SRC="/opt/wheelzone/backups/"
DST="gdrive:/lllBackUplll-WheelZone/Backups/"
LOG="/opt/wheelzone/backups/logs/push_drive_$(date +%F_%H-%M).log"

mkdir -p "$(dirname "$LOG")"
sync
sleep 1

rclone copy "$SRC" "$DST" \
  --exclude "logs/**" \
  --log-file="$LOG" \
  --log-level=INFO \
  --retries=5 \
  --low-level-retries=10 \
  --progress
