#!/usr/bin/env bash
set -euo pipefail
INPUT="${1:?Usage: $0 <input.(csv|xlsx|json)>}"
DB="${2:-$HOME/data/stock.db}"
LOG="$HOME/wheelzone-script-utils/logs/import_$(date +%F_%H%M%S).log"

mkdir -p "$(dirname "$DB")"
{
  echo "== $(date -Is) START import"
  scripts/import/import_stock_items.py "$INPUT" "$DB"
  scripts/backup/backup_rclone.sh "$DB"
  echo "== $(date -Is) DONE"
} | tee -a "$LOG"
