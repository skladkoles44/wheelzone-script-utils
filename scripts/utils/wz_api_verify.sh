#!/usr/bin/env bash
# == WZ :: API VERIFY (robust, logs+clipboard) ==
set -euo pipefail; IFS=$'\n\t'

PUB="${1:-79.174.85.106}"
BASE="http://${PUB}/api"

LOG_DIR="/storage/emulated/0/Download/project_44/Logs"; mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"; RUN_LOG="$LOG_DIR/wz_api_verify_${TS}.txt"

say(){ printf "%s\n" "$*" | tee -a "$RUN_LOG"; }
clip(){ command -v termux-clipboard-set >/dev/null 2>&1 && termux-clipboard-set < "$RUN_LOG" || true; }

COL=(31 32 33 34 35 36); CLR=${COL[$RANDOM%${#COL[@]}]}
printf "\033[%sm==[ WZ :: API VERIFY (robust) %s ]==\033[0m\n" "$CLR" "$TS" | tee -a "$RUN_LOG"
say "[EXT] BASE=$BASE"

# 1) Статусы ключевых эндпоинтов
for path in "/" "/docs" "/openapi.json" "/v1/health" "/v1/products?limit=1&offset=0" "/v1/products"; do
  code=$(curl -m 15 --compressed -H 'Accept: application/json' -sS -o /dev/null -w "%{http_code}" "$BASE$path" || echo 000)
  t=$(curl   -m 15 --compressed -H 'Accept: application/json' -sS -o /dev/null -w "%{time_total}" "$BASE$path" || echo NA)
  printf "  GET %-35s => %s %ss\n" "$path" "$code" "$t" | tee -a "$RUN_LOG"
done

# 2) Образец ответа из /v1/products (надёжный парс через файл)
say "[SAMPLE] items[0] из /v1/products?limit=1&offset=0 (robust)"
TMP_DIR="$(mktemp -d)"; BODY="$TMP_DIR/body.bin"; HDR="$TMP_DIR/hdr.txt"
set +e
curl -m 20 --compressed -H 'Accept: application/json' -sS -D "$HDR" "$BASE/v1/products?limit=1&offset=0" -o "$BODY"
RC=$?
set -e
SIZE=$(wc -c <"$BODY" 2>/dev/null || echo 0)
CT=$(grep -i '^Content-Type:' "$HDR" 2>/dev/null | awk '{$1=""; sub(/^: /,""); print}')
say "  [HDR] Content-Type: ${CT:-unknown}"
say "  [BODY] size=${SIZE} bytes, head(200): $(head -c 200 "$BODY" | tr -d '\n' | sed 's/\\/\\\\/g')"

if [ "$RC" -eq 0 ] && [ "$SIZE" -gt 0 ]; then
  python3 - "$BODY" <<'PY' | tee -a "$RUN_LOG"
import sys, json, pathlib
p = pathlib.Path(sys.argv[1])
try:
    with p.open('rb') as f:
        data = json.load(f)
    items = (data or {}).get("items") or []
    print(json.dumps(items[0] if items else {"note":"empty"}, ensure_ascii=False, indent=2))
except Exception as e:
    print(f"parse_error: {e}")
PY
else
  echo "  [ERR] curl rc=$RC, empty body" | tee -a "$RUN_LOG"
fi

echo "[LOG FILE] $RUN_LOG" | tee -a "$RUN_LOG"
clip
