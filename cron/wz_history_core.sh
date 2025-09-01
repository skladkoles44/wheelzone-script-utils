#!/usr/bin/env bash
# WZ Canon Delegator (repo-safe, MD5-locked)
# Это НЕ генератор. Прокси к оркестратору на VPS (API/Nginx) или SSH→мост.
# Канон живёт ТОЛЬКО на VPS: /root/wheelzone-script-utils/cron/wz_history_core.sh

: "${WZ_UUID_API:=}"                                  # напр. https://uuid.example.com
: "${WZ_UUID_TOKEN_FILE:=$HOME/.wz_uuid_token}"       # Bearer-токен
: "${VPS_HOST:=}"                                     # IP/домен VPS для SSH-фолбэка
: "${VPS_PORT:=2222}"
: "${WZ_BRIDGE_PATH:=/root/wheelzone-script-utils/scripts/utils/wz_uuid_bridge.sh}"

generate_fractal_uuid(){
  local ns="${1:-wz:delegator}"

  # Путь A: API через Nginx (если задан URL и есть токен)
  if [ -n "$WZ_UUID_API" ] && [ -r "$WZ_UUID_TOKEN_FILE" ]; then
    local tok; tok="$(head -c 4096 "$WZ_UUID_TOKEN_FILE" | tr -d '\r\n' || true)"
    if [ -n "$tok" ]; then
      local url="${WZ_UUID_API%/}/api/uuid/take?count=1&namespace=$(printf '%s' "$ns" | sed 's/ /%20/g')"
      local json; json="$(curl -fsS -H "Authorization: Bearer $tok" "$url" 2>/dev/null || true)"
      if [ -n "$json" ]; then
        python3 - "$json" <<'PY' || true
import json,sys
try:
    d=json.loads(sys.argv[1])
    ids=d.get("ids") or d.get("id") or []
    if isinstance(ids,list) and ids: print(ids[0]); sys.exit(0)
    if isinstance(ids,str): print(ids); sys.exit(0)
except: pass
sys.exit(1)
PY
        [ $? -eq 0 ] && return 0
      fi
    fi
  fi

  # Путь B: SSH → мост на VPS
  if [ -n "$VPS_HOST" ]; then
    ssh -p "$VPS_PORT" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "root@$VPS_HOST" bash -se <<'SH' "$ns" "$WZ_BRIDGE_PATH"
set -Eeuo pipefail
NS="$1"; BR="$2"
. "$BR" >/dev/null 2>&1 || { echo "BRIDGE_LOAD_FAIL" >&2; exit 2; }
type generate_fractal_uuid >/dev/null 2>&1 || { echo "NO_FUNC" >&2; exit 3; }
generate_fractal_uuid "$NS"
SH
    return $?
  fi

  echo "WZ_DELEGATOR_FAIL" >&2
  return 4
}

# Исполняемый режим
if [ "${1:-}" = "selftest" ]; then
  generate_fractal_uuid "manual:selftest" || exit $?
  exit 0
fi
# При source — просто определили функцию.
