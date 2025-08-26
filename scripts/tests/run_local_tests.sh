#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:33+03:00-1246758320
# title: run_local_tests.sh
# component: .
# updated_at: 2025-08-26T13:19:33+03:00

set -Eeuo pipefail
echo "[i] run chatend sanitize regress..."
"$HOME/wheelzone-script-utils/tests/chatend_sanitize_regress.sh"
echo "[OK] all local tests passed"
