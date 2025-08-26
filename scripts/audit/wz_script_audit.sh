#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:21+03:00-1554616440
# title: wz_script_audit.sh
# component: .
# updated_at: 2025-08-26T13:19:21+03:00

# WZ Fractal Script Auditor v4.0 — Termux + VPS + Noiton
set -euo pipefail
IFS=$'\n\t'

# === Фрактальная инициализация ===
declare -gA FRACTAL=(
  [VERSION]="4.0"
  [NODE_ID]="audit_$(date +%s | sha256sum | head -c 6)"
  [LEVEL]="0"
  [CACHE_DIR]="$HOME/.cache/wz_fractal/audit"
  [LOG_FILE]="$HOME/.local/var/log/wz_audit.fractal.ndjson"
  [REGISTRY]="$HOME/wz-wiki/registry/script_registry.fractal.yaml"
)

CHATLOG="${1:-$HOME/wzbuffer/chatlog_full.fractal.txt}"
mkdir -p "${FRACTAL[CACHE_DIR]}" "${FRACTAL[LOG_FILE]%/*}"
TMPDIR="$(mktemp -d -p "${FRACTAL[CACHE_DIR]}" wz_audit_XXXXXX)"

# === Логирование ===
fractal_log() {
  jq -cn \
    --arg ts "$(date -u +%FT%T.%3NZ)" \
    --arg node "${FRACTAL[NODE_ID]}" \
    --arg lvl "${1:-info}" \
    --arg msg "${2:-}" \
    --argjson meta "${3:-null}" \
    '{timestamp: $ts, node: $node, level: $lvl, message: $msg, meta: $meta}' \
    >> "${FRACTAL[LOG_FILE]}"
}

# === Блокировка ===
fractal_lock() {
  exec 9>"${FRACTAL[CACHE_DIR]}/.lock"
  if ! flock -n 9; then
    fractal_log "error" "Lock failed" '{"pid":'$(cat "${FRACTAL[CACHE_DIR]}/.lock")'}'
    exit 1
  fi
  echo $$ >&9
}

# === Парсинг скриптов из chatlog ===
parse_scripts() {
  local cache_key="scripts_$(sha256sum "$CHATLOG" | cut -d' ' -f1).cache"

  if [[ -f "${FRACTAL[CACHE_DIR]}/$cache_key" ]]; then
    cp "${FRACTAL[CACHE_DIR]}/$cache_key" "$TMPDIR/raw.lst"
    fractal_log "debug" "Using cached script list"
  else
    grep -oP '[a-zA-Z0-9_\-\/\.]+(\.fractal\.)?(sh|py|js|rb)' "$CHATLOG" |
      awk '{
        gsub(/.*\//, ""); $0=tolower($0); if ($0 ~ /\./) print
      }' | sort -u > "$TMPDIR/raw.lst"
    cp "$TMPDIR/raw.lst" "${FRACTAL[CACHE_DIR]}/$cache_key"
  fi
}

# === Верификация скриптов ===
verify_scripts() {
  declare -gA STATS=([registered]=0 [unregistered]=0 [missing]=0)

  > "$TMPDIR/registered.lst"
  > "$TMPDIR/unregistered.lst"
  > "$TMPDIR/missing.lst"

  while read -r script; do
    local found_path
    found_path=$(find "$HOME/wheelzone-script-utils" -type f -iname "$script" -print -quit 2>/dev/null || true)

    if [[ -n "$found_path" ]]; then
      if yq -e ".scripts[] | select(.filename == \"$script\")" "${FRACTAL[REGISTRY]}" &>/dev/null; then
        echo "$found_path" >> "$TMPDIR/registered.lst"
        ((STATS[registered]++))
      else
        echo "$found_path" >> "$TMPDIR/unregistered.lst"
        ((STATS[unregistered]++))
      fi
    else
      echo "$script" >> "$TMPDIR/missing.lst"
      ((STATS[missing]++))
    fi
  done < "$TMPDIR/raw.lst"
}

# === Отчёт YAML ===
generate_report() {
  local report_file="$HOME/wzbuffer/audit/report_$(date +%s).fractal.yaml"

  cat > "$report_file" <<EOFYAML
# WZ Fractal Audit Report
meta:
  version: "${FRACTAL[VERSION]}"
  timestamp: "$(date -Is)"
  node: "${FRACTAL[NODE_ID]}"
  level: "${FRACTAL[LEVEL]}"

scripts:
  registered: ${STATS[registered]}
  unregistered: ${STATS[unregistered]}
  missing: ${STATS[missing]}

integrity:
  sha256: $(sha256sum "$report_file" | cut -d' ' -f1)
EOFYAML

  echo "$report_file"
}

# === Интеграция с Noiton ===
sync_with_noiton() {
  local report_file="$1"
  if command -v wz_notify.sh &>/dev/null; then
    wz_notify.sh \
      --type "fractal_audit" \
      --title "🌀 Фрактальный аудит v${FRACTAL[VERSION]}" \
      --message "Узел: ${FRACTAL[NODE_ID]}\nУровень: ${FRACTAL[LEVEL]}" \
      --attach "$report_file" \
      --status "$([[ ${STATS[missing]} -eq 0 ]] && echo success || echo warning)" \
      --source "wz_script_audit.sh"
  fi
}

# === Основной блок ===
main() {
  fractal_lock
  trap 'rm -rf "$TMPDIR"; flock -u 9' EXIT

  fractal_log "info" "Audit started" '{"chatlog":"'"$CHATLOG"'"}'

  parse_scripts
  verify_scripts
  local report_file=$(generate_report)
  sync_with_noiton "$report_file"

  fractal_log "info" "Audit completed" '{"registered":'${STATS[registered]}',"unregistered":'${STATS[unregistered]}',"missing":'${STATS[missing]}'}'

  [[ ${STATS[missing]} -eq 0 ]] && exit 0 || exit 1
}

main "$@"
