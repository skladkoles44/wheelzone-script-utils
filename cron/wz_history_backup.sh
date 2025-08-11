#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
CORE="$HOME/wheelzone-script-utils/cron/wz_history_core.sh"
bash "$HOME/wheelzone-script-utils/scripts/utils/wz_history_fix_headers.sh" >/dev/null 2>&1 || true
exec bash "$CORE" --backup
