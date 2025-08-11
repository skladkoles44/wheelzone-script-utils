#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
echo "[i] run chatend sanitize regress..."
"$HOME/wheelzone-script-utils/tests/chatend_sanitize_regress.sh"
echo "[OK] all local tests passed"
