#!/usr/bin/env bash
# == WZ :: FINAL OPS ==
# Всё, что печатается, уходит в лог-файл в Загрузки и в буфер обмена (если есть termux-clipboard-set).
set -euo pipefail
IFS=$'\n\t'

# ---- Параметры окружения (редактируй при необходимости) ----
SRV="${SRV:-root@79.174.85.106}"
TRY_PORTS=(${TRY_PORTS:-2222 22})
BASE="${BASE:-http://79.174.85.106/api}"

# ---- Лог-файл в Загрузки ----
LOG_DIR="/storage/emulated/0/Download/project_44/Logs"; mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
RUN_LOG="$LOG_DIR/wz_final_ops_${TS}.txt"

# ---- Утилиты вывода ----
say(){ printf "%s\n" "$*" | tee -a "$RUN_LOG"; }
clip(){ command -v termux-clipboard-set >/dev/null 2>&1 && termux-clipboard-set < "$RUN_LOG" || true; }
jprint(){ # безопасный pretty JSON: jq || python || как есть
  if command -v jq >/dev/null 2>&1; then jq -r '.' || cat; else
    python3 - <<'PY' 2>/dev/null || cat
import sys,json
try:
  print(json.dumps(json.load(sys.stdin), ensure_ascii=False, indent=2))
except Exception:
  sys.stdout.write(sys.stdin.read())
PY
  fi
}

# ---- Цветной заголовок (рандом) ----
COL=(31 32 33 34 35 36); CLR=${COL[$RANDOM%${#COL[@]}]}
printf "\033[%sm==[ WZ :: FINAL OPS %s ]==\033[0m\n" "$CLR" "$TS" | tee -a "$RUN_LOG"

# ---- Определяем SSH порт ----
PORT=""
for p in "${TRY_PORTS[@]}"; do
  if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=7 -p "$p" "$SRV" "echo ok" >/dev/null 2>&1; then
    PORT="$p"; break
  fi
done
if [ -n "$PORT" ]; then
  say "[SSH] OK $SRV port=$PORT"
else
  say "[SSH] WARN: SSH недоступен на ${TRY_PORTS[*]} — продолжаю только с внешними HTTP-проверками"
fi

# ---- 1) Внешние смоки через nginx:80 ----
say "[EXT] BASE=$BASE"
for path in "/" "/docs" "/openapi.json" "/v1/health" "/v1/products?limit=1&offset=0" "/v1/products"; do
  code=$(curl -m 12 -sS -o /dev/null -w "%{http_code}" "$BASE$path" || echo "000")
  tt=$(curl -m 12 -sS -o /dev/null -w "%{time_total}" "$BASE$path" || echo "NA")
  printf "  GET %-35s => %s %ss\n" "$path" "$code" "$tt" | tee -a "$RUN_LOG"
done

# ---- 2) Сэмпл JSON из /v1/products?limit=1 ----
say "[SAMPLE] /v1/products?limit=1 (items[0] если есть)"
curl -m 12 -sS "$BASE/v1/products?limit=1&offset=0" \
| ( if command -v jq >/dev/null 2>&1; then jq '. as $r | ($r.items[0] // {"note":"empty"})'; else cat; fi ) \
| jprint | tee -a "$RUN_LOG"

# ---- 3) Сокеты и статус на сервере (если SSH доступен) ----
if [ -n "$PORT" ]; then
  say "[SRV] sockets uvicorn/nginx + systemd status (wz-api.service)"
  ssh -p "$PORT" "$SRV" 'bash -euo pipefail -s' <<'RMT' | sed 's/^/[SRV] /' | tee -a "$RUN_LOG"
(ss -ltnp || netstat -ltnp || true) 2>/dev/null | grep -E "(uvicorn|nginx)" || true
systemctl --no-pager --full status wz-api.service | sed -n "1,30p"
RMT
fi

# ---- 4) Хвост журнала uvicorn (если SSH доступен) ----
if [ -n "$PORT" ]; then
  say "[JOURNAL] tail -n 120 (wz-api.service)"
  ssh -p "$PORT" "$SRV" 'journalctl -u wz-api.service -n 120 --no-pager' \
    | sed 's/^/[JNL] /' | tee -a "$RUN_LOG" || true
fi

# ---- 5) nginx sanity (без правок) ----
if [ -n "$PORT" ]; then
  say "[NGINX] nginx -t && reload (без изменений)"
  ssh -p "$PORT" "$SRV" '/usr/sbin/nginx -t' | sed 's/^/[NGX] /' | tee -a "$RUN_LOG" || true
  ssh -p "$PORT" "$SRV" 'systemctl reload nginx || nginx -s reload || true' \
    | sed 's/^/[NGX] /' | tee -a "$RUN_LOG" || true
fi

# ---- 6) Мини-бенч /v1/products x5 ----
say "[BENCH] /v1/products x5"
for i in $(seq 1 5); do
  curl -m 12 -sS -o /dev/null -w "  #%d code=%{http_code} t=%{time_total}s\n" "$BASE/v1/products" $i
done | tee -a "$RUN_LOG"

# ---- Итоги ----
say "[LOG FILE] $RUN_LOG"
clip
