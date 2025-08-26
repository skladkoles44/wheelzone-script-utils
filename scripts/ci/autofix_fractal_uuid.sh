#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:22+03:00-596425713
# title: autofix_fractal_uuid.sh
# component: .
# updated_at: 2025-08-26T13:19:22+03:00

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
