#!/usr/bin/env bash
# name: WZ :: DB+API Bring-Up
# version: 1.4.0
# target: Termux (Android 15/HyperOS) -> SSH to VPS (systemd, PostgreSQL)
# usage:
#   wz_db_api_bringup.sh check [--env-file PATH]
#   wz_db_api_bringup.sh rotate --new-pass 'S3cr3t' [--env-file PATH]
#   wz_db_api_bringup.sh all    --new-pass 'S3cr3t' [--env-file PATH]
set -Eeuo pipefail; IFS=$'\n\t'

# ---------- CONFIG (можно переопределить env) ----------
: "${VPS_HOST:=79.174.85.106}"
: "${VPS_PORT:=2222}"
: "${API_PORT:=8000}"
: "${API_ENV:=/opt/wz-api/.env}"
: "${API_SERVICE:=wz-api.service}"
: "${DB_NAME:=wz}"
: "${DB_ROLE:=wz_app}"
: "${ENV_FILE:=$HOME/wheelzone-script-utils/configs/.env.wzdb}"
: "${DB_URL:=}"   # если пусто — соберём из ENV_FILE/переменных

LOG="${LOG:-$HOME/wzbuffer/wz_bringup.log}"
RUN_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

say(){ printf '[WZ] %s\n' "$*"; }
remote(){ ssh -p "$VPS_PORT" -o StrictHostKeyChecking=accept-new "root@$VPS_HOST" bash -se; }
need(){ command -v "$1" >/dev/null 2>&1 || { say "требуется '$1'"; exit 2; }; }

# ---------- ENV LOADER ----------
load_env(){
  local f="${1:-$ENV_FILE}"
  if [ -f "$f" ]; then
    set -a; . "$f"; set +a
    # если DATABASE_URL ещё пуст — соберём
    if [ -z "${DATABASE_URL:-}" ]; then
      : "${DB_HOST:=127.0.0.1}"; : "${DB_PORT:=5432}"
      DATABASE_URL="postgres://${DB_ROLE}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
      export DATABASE_URL
    fi
  fi
  # совместимость
  if [ -z "${DB_URL:-}" ] && [ -n "${DATABASE_URL:-}" ]; then
    DB_URL="$DATABASE_URL"
  fi
}

print_header(){
  say "Bring-Up start: ${RUN_TS}"
  say "VPS=$VPS_HOST:$VPS_PORT  API_PORT=$API_PORT  DB=$DB_NAME  ROLE=$DB_ROLE"
  [ -f "$ENV_FILE" ] && say "ENV_FILE=$ENV_FILE (загружен)"
}

# ---------- STEPS (REMOTE) ----------
step_db_probe(){ # \conninfo + наличие схемы core/ref
remote <<'SH'
set -Eeuo pipefail
echo "[WZ] psql conninfo:"
sudo -u postgres psql -d '"'"$DB_NAME"'"' -XtAc '\conninfo' || true
echo "[WZ] list schemas:"
sudo -u postgres psql -d '"'"$DB_NAME"'"' -XtAc "SELECT nspname FROM pg_namespace WHERE nspname IN ('ref','core','inventory','pricing','import','logs') ORDER BY 1;" || true
# safe-select из v_search_index если есть
HAS_VIEW=$(sudo -u postgres psql -d '"'"$DB_NAME"'"' -XtAc "SELECT to_regclass('core.v_search_index') IS NOT NULL;")
if [ "$HAS_VIEW" = "t" ]; then
  echo "[WZ] sample from core.v_search_index:"
  sudo -u postgres psql -d '"'"$DB_NAME"'"' -c "TABLE core.v_search_index LIMIT 3;" || true
else
  echo "[WZ] core.v_search_index: not present"
fi
# сетевые снимки (диагностика)
echo "[WZ] ss -ltn (5432, 8000):"
ss -ltn | awk 'NR==1 || /:5432|:8000/'
SH
}

step_db_rotate_pass(){ # NEW_PASS || DB_PASS
  local new_pass="${1:-}"
  [ -z "$new_pass" ] && new_pass="${DB_PASS:-}"
  [ -n "$new_pass" ] || { say "Пароль не задан — пропуск смены"; return 0; }
remote <<SH
set -Eeuo pipefail
echo "[WZ] ALTER ROLE $DB_ROLE (пароль скрыт)"
sudo -u postgres psql -d "$DB_NAME" -c "ALTER ROLE $DB_ROLE WITH PASSWORD '$(printf "%s" "$new_pass" | sed "s/'/''/g")';"
SH
}

step_api_patch_env(){ # правка DATABASE_URL в API_ENV
  local new_pass="${1:-}"
  [ -z "$new_pass" ] && new_pass="${DB_PASS:-CHANGE_ME}"
remote <<SH
set -Eeuo pipefail
if [ -f "$API_ENV" ]; then
  echo "[WZ] patch $API_ENV (DATABASE_URL)"
  if grep -q '^DATABASE_URL=' "$API_ENV"; then
    sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgres://$DB_ROLE:${new_pass}@127.0.0.1:5432/$DB_NAME|" "$API_ENV"
  else
    printf "DATABASE_URL=postgres://$DB_ROLE:${new_pass}@127.0.0.1:5432/$DB_NAME\n" >> "$API_ENV"
  fi
else
  echo "[WZ] $API_ENV отсутствует — пропуск"
fi
SH
}

step_api_restart(){
remote <<SH
set -Eeuo pipefail
echo "[WZ] systemctl restart $API_SERVICE"
systemctl daemon-reload || true
systemctl restart "$API_SERVICE" || true
sleep 1
systemctl --no-pager -l status "$API_SERVICE" || true
echo "[WZ] journal (tail 80):"
journalctl -u "$API_SERVICE" -n 80 --no-pager || true
SH
}

step_api_smoke(){
  local base="http://$VPS_HOST:$API_PORT"
  say "SMOKE: $base/health"
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "$base/health" || true
    echo
    say "SMOKE: $base/search?q=test (top)"
    curl -fsS "$base/search?q=test" 2>/dev/null | head -n 60 || true
    echo
  else
    say "curl не найден — пропуск HTTP смоков"
  fi
}

# ---------- ARGPARSE ----------
cmd="${1:-help}"; shift || true
NEW_PASS=""; CUSTOM_ENV=""
while [ $# -gt 0 ]; do
  case "$1" in
    --new-pass) NEW_PASS="${2:-}"; shift 2;;
    --env-file) CUSTOM_ENV="${2:-}"; shift 2;;
    *) echo "[WZ] нераспознанный аргумент: $1"; exit 2;;
  esac
done
[ -n "$CUSTOM_ENV" ] && ENV_FILE="$CUSTOM_ENV"

main(){
  need ssh; load_env "$ENV_FILE"; print_header
  case "$cmd" in
    check)
      step_db_probe        2>&1 | tee -a "$LOG"
      step_api_smoke       2>&1 | tee -a "$LOG"
      ;;
    rotate)
      step_db_rotate_pass "$NEW_PASS" 2>&1 | tee -a "$LOG"
      step_api_patch_env  "$NEW_PASS" 2>&1 | tee -a "$LOG"
      step_api_restart          2>&1 | tee -a "$LOG"
      step_api_smoke            2>&1 | tee -a "$LOG"
      ;;
    all)
      step_db_probe        2>&1 | tee -a "$LOG"
      step_db_rotate_pass "$NEW_PASS" 2>&1 | tee -a "$LOG"
      step_api_patch_env  "$NEW_PASS" 2>&1 | tee -a "$LOG"
      step_api_restart          2>&1 | tee -a "$LOG"
      step_api_smoke            2>&1 | tee -a "$LOG"
      ;;
    help|--help|-h)
      cat <<USAGE
[WZ] DB+API Bring-Up
  check                          — проверки БД и HTTP смоки
  rotate --new-pass P            — смена пароля роли, правка .env, рестарт API, смоки
  all --new-pass P               — всё подряд: проверка -> rotate -> рестарт -> смоки
  --env-file PATH                — явный путь к .env (по умолчанию: $HOME/wheelzone-script-utils/configs/.env.wzdb)
env:
  VPS_HOST=$VPS_HOST  VPS_PORT=$VPS_PORT
  API_PORT=$API_PORT  API_ENV=$API_ENV  API_SERVICE=$API_SERVICE
  DB_NAME=$DB_NAME    DB_ROLE=$DB_ROLE
  DATABASE_URL=${DATABASE_URL:-"(загружается из ENV_FILE)"}
log:
  $LOG
USAGE
      ;;
    *)
      say "неизвестная команда: $cmd"; exit 2;;
  esac
  say "Done @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
main
