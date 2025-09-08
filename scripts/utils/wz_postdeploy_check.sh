#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PUB_IP="${1:-79.174.85.106}"
BASE_HTTP="http://${PUB_IP}/api"
BASE_HTTPS="https://${PUB_IP}:8443/api"

LOG_DIR="/storage/emulated/0/Download/project_44/Logs"; mkdir -p "$LOG_DIR"
TS="$(date +%Y-%m-%d_%H-%M-%S)"
RUN_LOG="$LOG_DIR/wz_postdeploy_${TS}.txt"

say(){ printf "%s\n" "$*" | tee -a "$RUN_LOG"; }
clip(){ command -v termux-clipboard-set >/dev/null 2>&1 && termux-clipboard-set < "$RUN_LOG" || true; }

# 🎨 случайный цвет заголовка
COL=(31 32 33 34 35 36); CLR=${COL[$RANDOM%${#COL[@]}]}
printf "\033[%sm==[ WZ :: POSTDEPLOY ${TS} ]==\033[0m\n" "$CLR" | tee -a "$RUN_LOG"

check_endpoint(){
  local label="$1" ; local url="$2"
  local code time
  code=$(curl -m 10 -sS -o /dev/null -w "%{http_code}" "$url" || echo "000")
  time=$(curl -m 10 -sS -o /dev/null -w "%{time_total}" "$url" || echo "NA")
  printf "  %-28s => %s %ss\n" "$label" "$code" "$time" | tee -a "$RUN_LOG"
  [ "$code" = "200" ]
}

say "[SMOKE] HTTP via nginx  : $BASE_HTTP"
check_endpoint "GET /"                      "$BASE_HTTP/"                       || true
check_endpoint "GET /docs"                  "$BASE_HTTP/docs"                   || true
check_endpoint "GET /openapi.json"          "$BASE_HTTP/openapi.json"           || true
H_OK=true
check_endpoint "GET /v1/health"             "$BASE_HTTP/v1/health"              || H_OK=false
check_endpoint "GET /v1/products?limit=1"   "$BASE_HTTP/v1/products?limit=1"    || H_OK=false

say "[SMOKE] HTTPS :8443    : $BASE_HTTPS"
check_endpoint "GET /docs"                  "$BASE_HTTPS/docs"                   || true
check_endpoint "GET /openapi.json"          "$BASE_HTTPS/openapi.json"           || true
S_OK=true
check_endpoint "GET /v1/health"             "$BASE_HTTPS/v1/health"              || S_OK=false
check_endpoint "GET /v1/products?limit=1"   "$BASE_HTTPS/v1/products?limit=1"    || S_OK=false

# надёжный JSON-sample (без метрик в поток тела)
say "[SAMPLE] items[0] (robust, из HTTP)"
BODY="/data/data/com.termux/files/home/.cache/wz_products_${TS}.json"
curl -m 10 -sS "$BASE_HTTP/v1/products?limit=1&offset=0" -H 'Accept: application/json' -o "$BODY" || true

# покажем краткую шапку тела для диагностики
SIZE=$(wc -c < "$BODY" 2>/dev/null || echo 0)
HEAD=$(head -c 200 "$BODY" 2>/dev/null || true)
printf "  [SIZE] %s bytes\n  [HEAD] %s\n" "$SIZE" "$HEAD" | tee -a "$RUN_LOG"

python3 - "$BODY" <<'PY' | tee -a "$RUN_LOG"
import sys, json, pathlib
p = pathlib.Path(sys.argv[1])
try:
    data = json.loads(p.read_text())
    items = (data.get("items") or [])
    one = items[0] if items else {"note":"empty"}
    print(json.dumps(one, ensure_ascii=False, indent=2))
except Exception as e:
    print(f"[parse_error] {e}")
PY

# сводка
RES_HTTP=$([ "$H_OK" = true ] && echo OK || echo FAIL)
RES_HTTPS=$([ "$S_OK" = true ] && echo OK || echo FAIL)
say "[RESULT] HTTP=$RES_HTTP  HTTPS=$RES_HTTPS"
say "[LOG FILE] $RUN_LOG"
clip
