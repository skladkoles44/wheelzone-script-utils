#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:26+03:00-1683933110
# title: pipeline_import_backup.sh
# component: .
# updated_at: 2025-08-26T13:19:26+03:00

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
