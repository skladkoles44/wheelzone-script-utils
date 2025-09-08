#!/usr/bin/env bash
# fractal_uuid=1f2a4e77-3b6d-4eae-9b2d-5c1cf5d5f8aa
set -euo pipefail
REPORT="${1:-}"
if [ -z "$REPORT" ]; then
  REPORT="$(ls -1t /storage/emulated/0/Download/project_44/Logs/wz_final_sweep_*.txt 2>/dev/null | head -n1 || true)"
fi
if [ -z "$REPORT" ] || [ ! -f "$REPORT" ]; then
  echo "[ERR] Нет отчёта wz_final_sweep_*.txt"; exit 2
fi
python3 "$HOME/wheelzone-script-utils/scripts/utils/wz_autopatch_criticals.py" "$REPORT"
