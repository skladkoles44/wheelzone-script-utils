#!/usr/bin/env bash
set -Eeuo pipefail
OK=0; FAIL=0

log(){ printf "\033[1;92m[TEST]\033[0m %s\n" "$*"; }
bad(){ printf "\033[1;91m[FAIL]\033[0m %s\n" "$*"; }

req(){
  if ! command -v "$1" >/dev/null 2>&1; then
    bad "missing binary: $1"
    FAIL=$((FAIL+1))
  else
    log "found: $1"
    OK=$((OK+1))
  fi
}

# Требуемые инструменты
for b in man gzip tar python3 git; do req "$b"; done

# Сгенерить man-страницы, если есть генератор
GEN="$HOME/wheelzone-script-utils/scripts/utils/wz_gen_manpages.sh"
INS="$HOME/wheelzone-script-utils/scripts/utils/wz_install_manpages.sh"

[ -x "$GEN" ] && "$GEN" || true
[ -x "$INS" ] && "$INS" || true

# Проверка существования ключевых страниц
for p in "$HOME/wheelzone-script-utils/docs/man/check_gdrive.1"; do
  if [ -s "$p" ]; then
    log "exists: $p"
    OK=$((OK+1))
  else
    bad "missing or empty: $p"
    FAIL=$((FAIL+1))
  fi
done

# Проверка, что man видит страницу
if man -w check_gdrive >/dev/null 2>&1; then
  log "man path ok: check_gdrive"
  OK=$((OK+1))
else
  bad "man path not found: check_gdrive"
  FAIL=$((FAIL+1))
fi

# Итог
echo "OK=$OK FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
