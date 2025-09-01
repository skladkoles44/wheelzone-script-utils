#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
[ "${WZ_DEBUG:-0}" = "1" ] && set -x

GREEN='\033[1;92m'; NOC='\033[0m'
hdr(){ printf "${GREEN}==[ %s ]==${NOC}\n" "$*"; }
TS="$(date +%Y%m%d-%H%M%S)"; BUF="$HOME/wzbuffer/${TS}_wz_uuid_pool.log"
log(){ printf "%s\n" "$*" | tee -a "$BUF"; }

VPS_HOST="${VPS_HOST:-vps2}"
VPS_SHELL="${VPS_SHELL:-/bin/bash}"
COUNT="${WZ_COUNT_DEFAULT:-1}"
NS="${WZ_NS_DEFAULT:-wz:termux}"
FORMAT="${FORMAT:-json}"   # json|ids
ACTION="take"
USER_TOKEN=""

usage(){ cat <<USG
Usage:
  $(basename "$0") [--count N] [--ns NAMESPACE] [--host ALIAS] [--format json|ids] [--health] [--token BEARER]
USG
}

while [ $# -gt 0 ]; do
  case "$1" in
    --count)     COUNT="${2:-}"; shift 2;;
    --ns|--namespace) NS="${2:-}"; shift 2;;
    --host)      VPS_HOST="${2:-}"; shift 2;;
    --format)    FORMAT="${2:-json}"; shift 2;;
    --health)    ACTION="health"; shift;;
    --token)     USER_TOKEN="${2:-}"; shift 2;;
    -h|--help)   usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

hdr "WZ UUID :: START (buf: $BUF)"
log "[ENV] VPS_HOST=$VPS_HOST  NS=$NS  COUNT=$COUNT  FORMAT=$FORMAT  ACTION=$ACTION  TOKEN_SET=$([ -n "$USER_TOKEN" ] && echo yes || echo no)"

SSH_OPTS=(-T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -o ServerAliveInterval=10 -o ServerAliveCountMax=3)

set +e
OUT="$(
  ssh "${SSH_OPTS[@]}" "$VPS_HOST" "$VPS_SHELL" -s -- "$ACTION" "$NS" "$COUNT" "$USER_TOKEN" <<'REMOTE_CTRL' 2>&1
set -Eeuo pipefail
TMP="$(mktemp /tmp/.wz_uuid_remote.XXXXXX.sh)"
cat > "$TMP" <<'REMOTE_BODY'
#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
[ "${WZ_DEBUG:-0}" = "1" ] && set -x
GREEN='\033[1;92m'; NOC='\033[0m'; hdr(){ printf "${GREEN}==[ %s ]==${NOC}\n" "$*"; }

ACTION="${1:?}"; NS="${2-}"; COUNT="${3-1}"; USER_TOKEN="${4-}"

# ходим через nginx (для DEMO_TOKEN_A map)
BASE="http://127.0.0.1"
CURL_CMD=(curl -sS -i --http1.1 --max-time 8 --connect-timeout 3 -H 'Host: _')

# encode двоеточия
NS_ESC="${NS//:/%3A}"

# токен: --token > unit > proc > env
fetch_unit_token(){ systemctl cat wz-uuid-orch.service 2>/dev/null | sed -n 's/^[[:space:]]*Environment=WZ_UUID_TOKEN=//p' | tail -n1; }
fetch_proc_token(){ PID="$(pgrep -f 'uvicorn|uuid.*orch' | head -n1 || true)"; [ -n "$PID" ] && tr '\0' '\n' < "/proc/$PID/environ" | awk -F= '$1=="WZ_UUID_TOKEN"{print $2}' | tail -n1 || true; }
TOKEN="$USER_TOKEN"; [ -z "$TOKEN" ] && TOKEN="$(fetch_unit_token || true)"; [ -z "$TOKEN" ] && TOKEN="$(fetch_proc_token || true)"; [ -z "$TOKEN" ] && TOKEN="${WZ_UUID_TOKEN:-${UUID_TOKEN:-}}"
AUTH=(); [ -n "$TOKEN" ] && AUTH=(-H "Authorization: Bearer $TOKEN")

hdr "REMOTE :: svc status"
systemctl is-active --quiet wz-uuid-orch.service && echo "[OK] wz-uuid-orch active" || echo "[WARN] wz-uuid-orch not active"
systemctl is-active --quiet nginx && echo "[OK] nginx active" || echo "[WARN] nginx not active"

http_code(){ awk 'toupper($1) ~ /^HTTP\/[0-9.]+$/ {print $2; exit}'; }

if [ "$ACTION" = "health" ]; then
  hdr "REMOTE :: /health (via nginx)"
  "${CURL_CMD[@]}" "$BASE/health"
  exit 0
fi

try_get_ns(){           hdr "REMOTE :: GET ?ns=";         "${CURL_CMD[@]}" "${AUTH[@]}" "$BASE/api/uuid/take?count=${COUNT}&ns=${NS_ESC}"; }
try_get_namespace(){    hdr "REMOTE :: GET ?namespace=";  "${CURL_CMD[@]}" "${AUTH[@]}" "$BASE/api/uuid/take?count=${COUNT}&namespace=${NS_ESC}"; }
try_get_ns_slash(){     hdr "REMOTE :: GET /take/ ?ns=";  "${CURL_CMD[@]}" "${AUTH[@]}" "$BASE/api/uuid/take/?count=${COUNT}&ns=${NS_ESC}"; }

LAST=""
for attempt in try_get_ns try_get_namespace try_get_ns_slash; do
  RESP="$($attempt || true)"
  CODE="$(printf "%s\n" "$RESP" | http_code || true)"
  printf "[TRY] %s -> %s\n" "$attempt" "${CODE:-unknown}"
  printf "%s\n" "$RESP"
  LAST="$RESP"
  [ "$CODE" = "200" ] && exit 0
done

printf "%s\n" "$LAST"
exit 22
REMOTE_BODY
chmod +x "$TMP"
env WZ_DEBUG="${WZ_DEBUG:-0}" "$TMP" "$@"
RC=$?; rm -f "$TMP"; exit $RC
REMOTE_CTRL
)"; RC=$?
set -e

hdr "WZ UUID :: RESULT"
printf "%s\n" "$OUT" | tee -a "$BUF" >/dev/null

# ids-режим: достаём тело последнего ответа и печатаем .ids[]
if [ "$ACTION" != "health" ] && [ "$FORMAT" = "ids" ] && command -v jq >/dev/null 2>&1; then
  printf "%s\n" "$OUT" | tac | awk 'seen++==0{print;next} /^HTTP\/|^\r?$/{print;exit} {print}' | tac \
    | awk 'f{print} /^(\r)?$/{f=1}' | jq -r '.ids[]' 2>/dev/null | tee -a "$BUF" || true
fi

if [ $RC -ne 0 ]; then
  if printf "%s\n" "$OUT" | grep -q '^HTTP/1\.[01] 401'; then
    log "[HINT] 401 Missing/Bad token — попробуй --token DEMO_TOKEN_A (замапится в реальный) или укажи реальный токен."
  elif printf "%s\n" "$OUT" | grep -q '^HTTP/1\.[01] 403'; then
    log "[HINT] 403 Invalid token — проверь map и proxy_set_header Authorization \$wz_upstream_auth."
  elif printf "%s\n" "$OUT" | grep -q '^HTTP/1\.[01] 422'; then
    log "[HINT] 422 Validation — нужен ?ns=... (именно ns) и целочисленный count."
  fi
  log "exit_code=$RC (см. буфер: $BUF)"
  exit $RC
fi

hdr "WZ UUID :: DONE"; echo "[BUF] $BUF"
