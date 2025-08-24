#!/data/data/com.termux/files/usr/bin/bash
# autofix_fractal_uuid.sh — запускает батч-фиксер поверх репо (idempotent)
set -Eeuo pipefail

ROOT="${1:-.}"
BATCH="${BATCH:-120}"
MAX_DEPTH="${MAX_DEPTH:-12}"

if [ -x "./scripts/utils/fix_fractal_uuid.sh" ]; then
  ./scripts/utils/fix_fractal_uuid.sh "$ROOT" --batch "$BATCH" --max-depth "$MAX_DEPTH"
else
  echo "[WZ][ERR] scripts/utils/fix_fractal_uuid.sh not found or not executable" >&2
  exit 1
fi
