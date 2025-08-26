#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:21+03:00-4191697595
# title: backup_rclone.sh
# component: .
# updated_at: 2025-08-26T13:19:22+03:00

set -euo pipefail
SRC_DB="${1:-$HOME/data/stock.db}"
DST="gdrive:/wz-backups/stock.db"
rclone copy "$SRC_DB" "$DST" --progress
echo "OK backup -> $DST"
