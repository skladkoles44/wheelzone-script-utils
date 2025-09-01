#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

say(){ printf "[WZ] %s\n" "$*"; }

# Канонический путь на VPS
ALLOWED="/root/wheelzone-script-utils/cron/wz_history_core.sh"

# Репозиторий, который у тебя синхронится в Termux
REPO="$HOME/wheelzone-script-utils"

say "Сканирую репозиторий: $REPO"
mapfile -t HITS < <(grep -RIl --exclude-dir=.git -e 'generate_fractal_uuid' "$REPO" 2>/dev/null || true)
mapfile -t HITS2 < <(find "$REPO" -type f -name 'wz_history_core.sh' 2>/dev/null || true)

declare -A SEEN=()
COUNT=0
for p in "${HITS[@]}" "${HITS2[@]}"; do
  [ -f "$p" ] || continue
  [[ -n "${SEEN[$p]:-}" ]] && continue
  SEEN[$p]=1
  COUNT=$((COUNT+1))
  echo " - $p"
done

say "Всего найдено кандидатов: $COUNT"
say "Канон должен быть только здесь: $ALLOWED"
