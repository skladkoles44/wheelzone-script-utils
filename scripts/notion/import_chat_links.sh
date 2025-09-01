# uuid: 2025-08-26T13:19:31+03:00-1399120267
# title: import_chat_links.sh
# component: .
# updated_at: 2025-08-26T13:19:31+03:00

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PY_SCRIPT="$SCRIPT_DIR/import_chat_links.py"
LOG_FILE="$HOME/wzbuffer/logs/import_chat_links_run.log"
ENV_FILE="$HOME/.env.Loki"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] .env.Loki not found: $ENV_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

echo "[INFO] Starting import at $(date -Iseconds)" | tee -a "$LOG_FILE"
python3 "$PY_SCRIPT" "$@" 2>&1 | tee -a "$LOG_FILE"
echo "[INFO] Finished import at $(date -Iseconds)" | tee -a "$LOG_FILE"
