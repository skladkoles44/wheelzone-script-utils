#!/bin/bash

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
