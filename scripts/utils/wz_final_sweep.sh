#!/usr/bin/env bash
# WheelZone :: Final Sweep
# fractal_uuid=3a8c2a2c-87d7-4d73-8f6f-3c9f6a2c1e11
set -euo pipefail

LOG_DIR="/storage/emulated/0/Download/project_44/Logs"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$LOG_DIR/wz_final_sweep_${TS}.txt"

# корни (только существующие)
ROOTS=("$HOME/wheelzone-script-utils" "/opt/wz-api")
EXISTING=()
for d in "${ROOTS[@]}"; do [ -d "$d" ] && EXISTING+=("$d"); done
if [ ${#EXISTING[@]} -eq 0 ]; then
  echo "[ERR] нет доступных корней для сканирования" | tee "$OUT"
  exit 2
fi

echo "==[ FINAL SWEEP ${TS} ]=="            | tee "$OUT"
echo "[ROOTS] ${EXISTING[*]}"               | tee -a "$OUT"
echo "[LOG]   $OUT"                         | tee -a "$OUT"
echo                                         | tee -a "$OUT"

# общие исключения
EXCL='-not -path "*/.git/*" -not -path "*/.backup/*" -not -path "*/.bak/*" -not -path "*/__pycache__/*"'

run_grep() {
  local name="$1"; shift
  local pattern="$1"; shift
  local critical="$1"; shift   # 1=critical, 0=warn
  local tmp
  tmp="$(mktemp)"
  # ищем только по .py/.sh etc.
  find "${EXISTING[@]}" -type f \( -name "*.py" -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) $EXCL -print0 \
   | xargs -0 -I{} grep -nHE --color=never "$pattern" "{}" 2>/dev/null > "$tmp" || true
  local count; count=$(wc -l < "$tmp" | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    local tag; tag=$([ "$critical" -eq 1 ] && echo "CRITICAL" || echo "WARN")
    echo "[$tag] $name — найдено: $count"           | tee -a "$OUT"
    sed -n '1,200p' "$tmp"                           | tee -a "$OUT"
    echo                                             | tee -a "$OUT"
  else
    echo "[OK] $name — не найдено"                  | tee -a "$OUT"
  fi
  rm -f "$tmp"
  return 0
}

# проверки
run_grep "subprocess с shell=True" \
  'subprocess\.(run|Popen|call|check_output)\([^)]*shell[[:space:]]*=[[:space:]]*True' 1

run_grep "двойные запятые в subprocess.run" \
  'subprocess\.run\(.*,,.*\)' 1

run_grep "SQL в f-строке в execute(...)" \
  'execute\([^)]*f["'\'']' 1

run_grep "SQL конкатенации в execute(...)" \
  'execute\(\s*["'\''][^"'\''"]*["'\'']\s*\+' 1

run_grep "logger f-строки" \
  'logger\.(debug|info|warning|error|critical)\(\s*f["'\'']' 0

echo "==[ SUMMARY ]=="                               | tee -a "$OUT"
# короткая сводка по меткам
grep -E '^\[(OK|WARN|CRITICAL)\]' "$OUT"             | tee -a "$OUT"

# код возврата: CRITICAL -> 1, иначе 0
if grep -q '^\[CRITICAL\]' "$OUT"; then
  echo "[EXIT] CRITICAL найдены — код 1"             | tee -a "$OUT"
  exit 1
fi
echo "[EXIT] без CRITICAL — код 0"                   | tee -a "$OUT"
exit 0
