#!/data/data/com.termux/files/usr/bin/bash
# WZ Notify (adaptive version)
set -euo pipefail
IFS=$'\n\t'

# ==== defaults ====
TITLE="WZ Notify"
MSG=""
PRIORITY="high"

# ==== parse args ====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --msg)
      MSG="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    *)
      echo "❌ ERROR: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ==== notify ====
if [[ -n "$MSG" ]]; then
  if command -v termux-notification >/dev/null 2>&1; then
    termux-notification --title "$TITLE" --content "$MSG" --priority "$PRIORITY"
  else
    echo "📢 [$TITLE] $MSG"
  fi
fi
