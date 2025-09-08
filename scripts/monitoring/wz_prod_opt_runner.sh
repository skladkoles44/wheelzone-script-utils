#!/usr/bin/env bash
# == WZ :: PROD-оптимизация v3.2 — runner (API smoke + p95 bench + отчёт YAML) ==
set -euo pipefail; IFS=$'\n\t'

# --- Параметры ---
BASE_URL="${1:-https://api.skladkoles44.ru/api}"   # базовый URL API
OUT_DIR="${2:-$HOME/storage/downloads}"            # куда класть отчёт
RUNS="${RUNS:-20}"                                 # кол-во прогонов на метрику
TIMEOUT="${TIMEOUT:-5}"                            # таймаут на запрос, сек
AUTH_USER="${AUTH_USER:-}"                         # basic user (если требуется)
AUTH_PASS="${AUTH_PASS:-}"                         # basic pass (если требуется)

TS="$(date +%Y%m%d_%H%M%S)"
LOG="$OUT_DIR/wz_prod_opt_runner_${TS}.log"
REPORT="$OUT_DIR/wz_prod_opt_report_${TS}.yaml"
mkdir -p "$OUT_DIR"

log(){ printf "%s %s\n" "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG" >&2; }

# --- цельные эндпоинты для бенча (можешь править) ---
mapfile -t ENDPOINTS < <(cat <<'EOF'
/v1/health
/docs
/openapi.json
/v1/products?limit=1&offset=0
EOF
)

# --- curl флаги ---
CURL_BASE=(-sS -m "$TIMEOUT" --connect-timeout 3 -w '%{http_code} %{time_total}\n' -o /dev/null)
if [[ -n "${AUTH_USER}${AUTH_PASS}" ]]; then
  CURL_BASE=(--user "${AUTH_USER}:${AUTH_PASS}" "${CURL_BASE[@]}")
fi

smoke_one(){
  local url="$1"
  local out; out="$(curl "${CURL_BASE[@]}" "$url" 2>/dev/null || true)"
  local code time; code="$(awk '{print $1}' <<<"$out")"; time="$(awk '{print $2}' <<<"$out")"
  printf "%s %s\n" "$code" "${time:-NA}"
}

bench_p95(){
  # читает с stdin список таймингов (сек), возвращает p95
  awk '
  {if($1 ~ /^[0-9.]+$/) a[n++]=$1}
  END{
    if(n==0){print "NA"; exit}
    asort(a)
    p=int(0.95*(n-1))+1
    print a[p]
  }'
}

# --- SMOKE & BENCH ---
declare -A P95_CODE
declare -A P95_TIME
declare -A FIRST_CODES

log "[SMOKE] BASE=$BASE_URL"
for ep in "${ENDPOINTS[@]}"; do
  full="${BASE_URL}${ep}"
  log "  -> $full"
  # первый код статуса для отчёта
  read -r code tsec < <(smoke_one "$full")
  FIRST_CODES["$ep"]="$code"

  # бенч итерациями
  times=()
  for i in $(seq 1 "$RUNS"); do
    read -r c tt < <(smoke_one "$full")
    [[ "$c" =~ ^[0-9]{3}$ ]] || continue
    times+=("$tt")
  done
  p95="$(printf "%s\n" "${times[@]}" | bench_p95)"
  P95_TIME["$ep"]="$p95"
  P95_CODE["$ep"]="$code"
done

# --- СБОРКА YAML отчёта по твоему формату ---
cat > "$REPORT" <<YML
# WZ Optimization Report v3.2
meta:
  ts: "$(date -u +%FT%TZ)"
  base_url: "$BASE_URL"
  runs: $RUNS
  timeout_s: $TIMEOUT
smoke:
$(for ep in "${ENDPOINTS[@]}"; do
  printf "  - endpoint: \"%s\"\n    code: %s\n    p95_s: %s\n" "$ep" "${P95_CODE[$ep]}" "${P95_TIME[$ep]}"
done)
changes: []          # заполняется после правок: security|reliability|perf|simplify
effect:
  performance: ""     # опиши выигрыш (%, p95 до/после)
  methodology: "N=$RUNS, p95 на curl; одинаковые условия"
  runs: $RUNS
risks: []
api_contract: true
explanation: "Контракт не менялся. Изменения касаются невидимых для клиента аспектов."
env:
  language: "Bash 5+"
  dependencies: "curl, awk"
bench:
  command: "RUNS=$RUNS BASE_URL=$BASE_URL ./wz_prod_opt_runner.sh"
  metrics: "HTTP code, p95 (сек)"
rollback:
  steps:
    - "Revert конфигов/патчей согласно бэкапам/PR revert"
    - "nginx -t && systemctl reload nginx (если затрагивался proxy)"
YML

log "[DONE] Отчёт: $REPORT"
log "[LOG FILE] $LOG"
printf "%s\n" "$REPORT"
