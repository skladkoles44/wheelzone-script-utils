#!/usr/bin/env bash
# WheelZone :: Audit Auto-Registration
# fractal_uuid: "c0b65d2a-4d5e-4c7b-9a6f-1f2d2b7a9a91"
# Version: 1.0.0
# Author: Себастьян Перейра
# Purpose: Инвентаризация текущей автогенерации шапок/registry и сравнение факта с желаемой моделью.
# Logs: /storage/emulated/0/Download/project_44/Logs

set -Eeuo pipefail
IFS=$'\n\t'

UTIL="$HOME/wheelzone-script-utils"
WIKI="$HOME/wz-wiki"
LOG_DIR="/storage/emulated/0/Download/project_44/Logs"
TS="$(date +%Y%m%d_%H%M%S)"
LOG="$LOG_DIR/wz_audit_autoreg_${TS}.log"
mkdir -p "$LOG_DIR"

say(){ printf '%s %s\n' "$1" "$2" | tee -a "$LOG"; }
hdr(){ printf '==[ %s ]== %s\n' "$1" "$2" | tee -a "$LOG"; }

hdr "TARGETS" "UTIL=$UTIL  WIKI=$WIKI"
[ -d "$UTIL" ] || { say "[ERR]" "нет каталога $UTIL"; exit 2; }
[ -d "$WIKI" ] || { say "[ERR]" "нет каталога $WIKI"; exit 2; }

# 1) Хуки и утилиты
hdr "HOOKS" "поиск git hooks"
for repo in "$UTIL" "$WIKI"; do
  say "[REPO]" "$repo"
  for h in pre-commit post-commit pre-push; do
    f="$repo/.git/hooks/$h"
    if [ -f "$f" ]; then
      first="$(head -n 1 "$f" | tr -d '\r')"
      grep -q 'wz_autoreg' "$f" && mark="(+ wz_autoreg)" || mark=""
      say "  - $h" "$f $mark | shebang: ${first}"
    else
      say "  - $h" "—"
    fi
  done
done

# 2) Утилиты WZ
hdr "TOOLS" "поиск wz_* автогенераторов"
grep -RIl --exclude-dir .git -e 'wz_autoreg' -e 'wz_register_script' "$UTIL" "$WIKI" 2>/dev/null | sed 's/^/  • /' | tee -a "$LOG" || true

# 3) Проверка fractal_uuid/Purpose/Logs в скриптах utils/
hdr "SCRIPTS" "вставленные хедеры"
shopt -s nullglob
missing=0; ok=0
declare -a BAD
for f in "$UTIL"/scripts/**/*.sh "$UTIL"/scripts/*.sh "$UTIL"/scripts/**/*.py "$UTIL"/scripts/*.py; do
  [ -f "$f" ] || continue
  head20="$(head -n 20 "$f" 2>/dev/null || true)"
  need=()
  echo "$head20" | grep -q 'fractal_uuid:' || need+=("fractal_uuid")
  echo "$head20" | grep -q 'Purpose:'      || need+=("Purpose")
  echo "$head20" | grep -q 'Logs:'         || need+=("Logs")
  if [ "${#need[@]}" -gt 0 ]; then
    say "[MISS]" "$f -> ${need[*]}"
    BAD+=("$f"); missing=$((missing+1))
  else
    say "[OK]" "$f"
    ok=$((ok+1))
  fi
done
say "[SUMMARY]" "scripts ok=$ok missing=$missing"

# 4) Сверка registry vs scripts
hdr "REGISTRY" "валидность путей и уникальность UUID"
reg_missing=0; reg_ok=0; dup=0
declare -A SEEN
for y in "$WIKI"/registry/*.yaml; do
  [ -f "$y" ] || continue
  id=$(grep -E '^id:' "$y" | sed 's/id:\s*//')
  path=$(grep -E '^script_path:' "$y" | sed 's/script_path:\s*//')
  uuid=$(grep -E '^fractal_uuid:' "$y" | sed 's/fractal_uuid:\s*"\(.*\)"/***REMOVED***/')
  abs="$UTIL/$path"
  if [ ! -f "$abs" ]; then
    say "[MISS]" "registry:$id -> отсутствует файл: $abs"
    reg_missing=$((reg_missing+1))
  else
    say "[OK]" "registry:$id -> $abs"
    reg_ok=$((reg_ok+1))
  fi
  if [ -n "${SEEN[$uuid]:-}" ]; then
    say "[DUP]" "UUID=$uuid у $id и ${SEEN[$uuid]}"
    dup=$((dup+1))
  else
    SEEN[$uuid]="$id"
  fi
done
say "[SUMMARY]" "registry ok=$reg_ok missing=$reg_missing dup_uuid=$dup"

# 5) Итог и подсказки
hdr "NEXT" "что починить"
if [ $missing -gt 0 ]; then
  say "[FIX]" "проставь шапку (fractal_uuid/Purpose/Logs) в скриптах выше или включи авто-инъекцию в pre-commit"
fi
if [ $reg_missing -gt 0 ]; then
  say "[FIX]" "исправь script_path в соответствующих registry/*.yaml"
fi
if [ $dup -gt 0 ]; then
  say "[FIX]" "обнаружены дублирующиеся UUID — перегенерируй один из них"
fi

hdr "DONE" "log: $LOG"
