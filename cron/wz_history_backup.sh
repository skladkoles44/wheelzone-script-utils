#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:07+03:00-1843005480
# title: wz_history_backup.sh
# component: .
# updated_at: 2025-08-26T13:19:07+03:00

set -Eeuo pipefail
CORE="$HOME/wheelzone-script-utils/cron/wz_history_core.sh"
bash "$HOME/wheelzone-script-utils/scripts/utils/wz_history_fix_headers.sh" >/dev/null 2>&1 || true
exec bash "$CORE" --backup
