#!/usr/bin/env bash
set -euo pipefail
SRC_DB="${1:-$HOME/data/stock.db}"
DST="gdrive:/wz-backups/stock.db"
rclone copy "$SRC_DB" "$DST" --progress
echo "OK backup -> $DST"
