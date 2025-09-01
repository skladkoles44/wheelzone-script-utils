#!/usr/bin/env bash
set -Eeuo pipefail

# === Config (override via env) ===
VPS_HOST="${VPS_HOST:-79.174.85.106}"
VPS_PORT="${VPS_PORT:-2222}"
REMOTE_ACCESS_LOG="${REMOTE_ACCESS_LOG:-/var/log/nginx/wz-uuid-orch.access.json}"
REMOTE_URL="${REMOTE_URL:-http://127.0.0.1/api/uuid/take?count=1&ns=wz:probe}"
LOCAL_HTTP="${LOCAL_HTTP:-18080}"   # локальный порт туннеля -> 127.0.0.1:80
SLEEP_SMALL="${SLEEP_SMALL:-1}"
TAIL_N="${TAIL_N:-6}"

# === Coloring (enabled only on TTY and when NO_COLOR != 1) ===
_use_color=0
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then _use_color=1; fi
if [ "${_use_color}" = "1" ]; then
  _G=$'\033[1;92m'; _Y=$'\033[1;93m'; _R=$'\033[1;91m'; _Z=$'\033[0m'
else
  _G=''; _Y=''; _R=''; _Z=''
fi

say()  { printf '%s==[ %s ]==%s\n' "$_G" "$*" "$_Z"; }
ok()   { printf '%s[OK]%s %s\n'    "$_G" "$_Z" "$*"; }
warn() { printf '%s[WARN]%s %s\n'  "$_Y" "$_Z" "$*"; }
err()  { printf '%s[ERR]%s %s\n'   "$_R" "$_Z" "$*"; }

_tpid=""

cleanup() {
  if [ -n "$_tpid" ] && kill -0 "$_tpid" 2>/dev/null; then
    kill "$_tpid" || true
  fi
}
trap 'cleanup' EXIT INT TERM

say "UUID API twin check on ${VPS_HOST}:${VPS_PORT}"

# --- 1) Remote checklist (VPS) ---
ssh -p "${VPS_PORT}" "root@${VPS_HOST}" bash -se <<'REMOTE'
set -Eeuo pipefail

# Параметры с дефолтами (можно переопределить через env при вызове ssh)
REMOTE_ACCESS_LOG="${REMOTE_ACCESS_LOG:-/var/log/nginx/wz-uuid-orch.access.json}"
REMOTE_URL="${REMOTE_URL:-http://127.0.0.1/api/uuid/take?count=1&ns=wz:probe}"
SLEEP_SMALL="${SLEEP_SMALL:-1}"
TAIL_N="${TAIL_N:-6}"

# Цвета на удалённой стороне: только если NO_COLOR!=1 и при наличии TTY
_use_color=0
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then _use_color=1; fi
if [ "${_use_color}" = "1" ]; then
  _G=$'\033[1;92m'; _Y=$'\033[1;93m'; _R=$'\033[1;91m'; _Z=$'\033[0m'
else
  _G=''; _Y=''; _R=''; _Z=''
fi

ok()   { printf '%s[OK]%s %s\n'   "$_G" "$_Z" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$_Y" "$_Z" "$*"; }
err()  { printf '%s[ERR]%s %s\n'  "$_R" "$_Z" "$*"; }

# 1) nginx -t
if nginx -t >/dev/null 2>&1; then ok 'nginx -t: syntax ok'; else err 'nginx -t: FAIL'; exit 1; fi

# 2) include conf.d
if nginx -T 2>/dev/null | grep -qF 'include /etc/nginx/conf.d/*.conf'; then
  ok 'http{} includes conf.d/*.conf'
else
  err "http{} doesn't include conf.d/*.conf"
  exit 1
fi

# 3) log_format wz_ns_main — key="$wz_key_log" и rid
FORMAT_BLOCK="$(nginx -T 2>/dev/null | awk '/log_format[[:space:]]+wz_ns_main/,/;[[:space:]]*$/' || true)"

if printf '%s\n' "$FORMAT_BLOCK" | grep -qF 'key="$wz_key_log"'; then
  ok 'log_format has key="$wz_key_log"'
else
  err 'log_format missing key="$wz_key_log"'
  printf '%s\n' "$FORMAT_BLOCK"
  exit 1
fi

if printf '%s\n' "$FORMAT_BLOCK" | grep -qF 'rid="$upstream_http_x_request_id"'; then
  ok 'log_format has rid="$upstream_http_x_request_id"'
else
  warn 'log_format without rid="$upstream_http_x_request_id" (не критично)'
fi

# 4) bind только loopback :80 (TLS локально опционален)
LISTENS="$(nginx -T 2>/dev/null | grep -E '^[[:space:]]*listen ' | sed -E 's/^[[:space:]]+//')"

if printf '%s\n' "$LISTENS" | grep -qE '^listen 127\.0\.0\.1:80(;| )'; then
  ok 'listen 127.0.0.1:80'
else
  err 'listen 127.0.0.1:80 not found'
  printf '%s\n' "$LISTENS"
  exit 1
fi

if printf '%s\n' "$LISTENS" | grep -qE '^listen 127\.0\.0\.1:443'; then
  warn 'listen 127.0.0.1:443 present (локальный TLS). Ок, если это задумывалось.'
else
  ok 'no local TLS listener (ожидаемо для внутреннего HTTP)'
fi

# 5) logrotate правило
if [ -r "/etc/logrotate.d/wz-uuid-orch" ]; then
  ok 'logrotate rule present'
else
  warn 'logrotate rule not found'
fi

# 6) UFW (если установлен): 80/443 deny
if command -v ufw >/dev/null 2>&1; then
  USTAT="$(ufw status || true)"
  if printf '%s\n' "$USTAT" | grep -qE '(^| )80/(tcp|TCP)[[:space:]]+DENY'; then ok 'UFW: 80/tcp denied'; else warn 'UFW: 80/tcp not denied'; fi
  if printf '%s\n' "$USTAT" | grep -qE '(^| )443/(tcp|TCP)[[:space:]]+DENY'; then ok 'UFW: 443/tcp denied'; else warn 'UFW: 443/tcp not denied'; fi
else
  warn 'UFW not installed — skip firewall checks'
fi

# 7) Смоук x2 и хвост логов
curl -sS -D - -o /dev/null -H 'Authorization: Bearer DEMO_TOKEN_A' "$REMOTE_URL" >/dev/null || true
sleep "$SLEEP_SMALL"
curl -sS -D - -o /dev/null -H 'Authorization: Bearer DEMO_TOKEN_B' "$REMOTE_URL" >/dev/null || true
sleep "$SLEEP_SMALL"

if [ -r "$REMOTE_ACCESS_LOG" ]; then
  TAIL_OUT="$(tail -n "$TAIL_N" "$REMOTE_ACCESS_LOG" | sed -E 's/[[:space:]]+/ /g')"
  printf '%s\n' "$TAIL_OUT"
  if printf '%s\n' "$TAIL_OUT" | grep -qF 'key="Bearer ****"'; then
    ok 'access log: Bearer masked (****)'
  else
    err 'access log: Bearer mask NOT found'
    exit 1
  fi
  if printf '%s\n' "$TAIL_OUT" | grep -qE 'key="Bearer [A-Za-z0-9._~+/=-]{6,}"'; then
    err 'access log: RAW Bearer leaked!'
    exit 1
  else
    ok 'access log: no raw Bearer detected'
  fi
else
  err "access log not readable: $REMOTE_ACCESS_LOG"
  exit 1
fi

ok 'Remote checklist passed'
REMOTE

# --- 2) Open SSH tunnel (local 127.0.0.1:${LOCAL_HTTP} -> VPS 127.0.0.1:80) ---
say "open SSH tunnel :${LOCAL_HTTP} -> 127.0.0.1:80 on ${VPS_HOST}"
ssh -p "${VPS_PORT}" -N \
  -L "${LOCAL_HTTP}:127.0.0.1:80" \
  -o ExitOnForwardFailure=yes \
  "root@${VPS_HOST}" &
_tpid="$!"

# Wait for port to be ready (nc если есть, иначе /dev/tcp)
_ready=0
if command -v nc >/dev/null 2>&1; then
  for _i in $(seq 1 20); do
    if nc -z 127.0.0.1 "${LOCAL_HTTP}" >/dev/null 2>&1; then _ready=1; break; fi
    sleep 0.2
  done
else
  for _i in $(seq 1 20); do
    ( exec 3<>"/dev/tcp/127.0.0.1/${LOCAL_HTTP}" ) 2>/dev/null && { _ready=1; break; }
    sleep 0.2
  done
fi

if [ "${_ready}" != "1" ]; then
  err "tunnel not established on :${LOCAL_HTTP}"
  exit 1
fi
ok "tunnel up on 127.0.0.1:${LOCAL_HTTP}"

# --- 3) Local smokes via tunnel ---
say 'local smoke A (HTTP via tunnel)'
curl -sS -D - -o /dev/null \
  -H 'Authorization: Bearer DEMO_TOKEN_A' \
  "http://127.0.0.1:${LOCAL_HTTP}/api/uuid/take?count=1&ns=wz:probe" | sed -n '1,20p'

sleep "${SLEEP_SMALL}"

say 'local smoke B (HTTP via tunnel)'
curl -sS -D - -o /dev/null \
  -H 'Authorization: Bearer DEMO_TOKEN_B' \
  "http://127.0.0.1:${LOCAL_HTTP}/api/uuid/take?count=1&ns=wz:probe" | sed -n '1,20p'

ok 'Twin check complete'
