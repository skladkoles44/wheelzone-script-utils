#!/usr/bin/env bash
# WheelZone :: Risky Autofix Runner
# fractal_uuid=9c6d2a3e-7f1a-4c57-9d0b-7e3e9d5b2c11
set -euo pipefail

LOG_DIR="/storage/emulated/0/Download/project_44/Logs"
AUTOFIX="$HOME/wheelzone-script-utils/scripts/utils/wz_autofix_risky.py"

# 1) выбрать лог (если LOG не задан/файл не существует — берём самый свежий)
LOG="${LOG:-}"
if [ -z "${LOG}" ] || [ ! -f "${LOG}" ]; then
  LOG="$(ls -1t "$LOG_DIR"/wz_autofix_*.jsonl 2>/dev/null | head -n1 || true)"
fi

echo "[INFO] LOG=${LOG:-<none>}"

# 2) собрать список risky .py из лога (если он есть)
PYLIST=""
if [ -n "${LOG}" ] && [ -f "${LOG}" ]; then
  if command -v jq >/dev/null 2>&1; then
    PYLIST="$(jq -r 'select((.risky|length)>0 and (.path|endswith(".py"))) | .path' "$LOG" | sort -u || true)"
  else
    PYLIST="$(grep -E '"risky":\[' "$LOG" | grep -oE '"/[^"]+\.py"' | tr -d '"' | sort -u || true)"
  fi
fi

# 3) запустить автофикс
if [ -n "$PYLIST" ]; then
  echo "[RUN] targeted risky autofix from JSONL…"
  python3 "$AUTOFIX" --from-jsonl "$LOG"
else
  echo "[RUN] no JSONL targets -> apply-all on ~/wheelzone-script-utils"
  python3 "$AUTOFIX" --apply-all "$HOME/wheelzone-script-utils"
fi

# 4) показать сводку и что изменилось
RLOG="$(ls -1t "$LOG_DIR"/wz_risky_autofix_*.jsonl 2>/dev/null | head -n1 || true)"
echo "[RLOG] ${RLOG:-<none>}"
if [ -n "$RLOG" ] && [ -f "$RLOG" ]; then
  echo "[SUMMARY]"
  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.lvl=="INFO" and .path) | [.path, ( (.fixed//[])|join(",")), ( (.patches//[])|join(",")) ] | @tsv' "$RLOG" | column -t
  else
    grep -E '"lvl":"INFO".*"path"' "$RLOG" || true
  fi
fi

# 5) показать созданные подсказки *.patch.py и бэкапы
echo "[PATCH HINTS]"
find "$HOME/wheelzone-script-utils" -type f \( -name "*.open_write.patch.py" -o -name "*.shell.patch.py" \) -print 2>/dev/null || true

echo "[BACKUPS]"
find "$HOME/wheelzone-script-utils" -maxdepth 3 -type f -name ".bak.autofix.*.py" -print 2>/dev/null || true
