#!/data/data/com.termux/files/usr/bin/bash
# Wrapper for wz_notify.py v3.4.0

SCRIPT="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.py"
PYTHON=$(which python3)

exec "$PYTHON" "$SCRIPT" "$@"
