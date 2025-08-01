#!/data/data/com.termux/files/usr/bin/bash
# generate_uuid.sh v4.1.0 — WZ Unified UUID Generator (Fractal)
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="${0%/*}"
PY_GENERATOR="$SCRIPT_DIR/generate_uuid.py"
VERSION="4.1.0"

generate_uuid() {
  if command -v python3 &>/dev/null && [ -f "$PY_GENERATOR" ]; then
    python3 "$PY_GENERATOR" "$@"
  else
    python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py | tr '[:upper:]' '[:lower:]'
  fi
}

case "${1:-}" in
  --help|-h)
    echo "WZ UUID Generator v$VERSION"
    echo "Usage: $(basename "$0") [--slug | --time | --quantum]"
    exit 0
    ;;
  --version)
    echo "$VERSION"
    exit 0
    ;;
  --slug)
    uuid=$(generate_uuid)
    echo "${uuid:0:8}"
    ;;
  --time)
    echo "$(date +%Y%m%d)-$(generate_uuid | cut -c1-6)"
    ;;
  --quantum)
    echo "uuid-$(date +%Y%m%d%H%M%S)-$(generate_uuid | cut -c1-6)"
    ;;
  *)
    generate_uuid
    ;;
esac
