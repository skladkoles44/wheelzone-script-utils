#!/usr/bin/env bash
# WZ Artifact: wz_ports_watchdog.sh
# WZ-Fractal-UUID: TBD
# WZ-Registry-Link: wz-wiki/registry/ports_map.yaml
# Role: периодически дергает wz_ports_audit.sh и пишет JSON-лог/нотификацию.
# ВНИМАНИЕ: ENABLE_WATCHDOG=false — по умолчанию выключен.

set -euo pipefail
ENABLE_WATCHDOG="${ENABLE_WATCHDOG:-false}"   # переключатель
INTERVAL_SEC="${INTERVAL_SEC:-600}"           # 10 минут по умолчанию
NODE="${WZ_NODE:-}"                           # опционально фиксируем узел
SU_DIR="${WZ_SU_DIR:-$HOME/wheelzone-script-utils}"
AUDITOR="${AUDITOR:-$SU_DIR/scripts/utils/wz_ports_audit.sh}"
LOG_DIR="${LOG_DIR:-$HOME/wzbuffer/ports_watchdog_logs}"
mkdir -p "$LOG_DIR"

ts(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
j(){ printf '%s\t{"lvl":"%s","msg":%s%s}\n' "$(ts)" "$1" "$2" "${3:-}"; }
info(){ j INFO  "$1" "$2"; }
warn(){ j WARN  "$1" "$2"; }
err(){  j ERROR "$1" "$2"; }

if [[ "$ENABLE_WATCHDOG" != "true" ]]; then
  warn "\"watchdog disabled\"" ",\"hint\":\"export ENABLE_WATCHDOG=true to enable\""
  exit 0
fi

if [[ ! -x "$AUDITOR" ]]; then
  err "\"auditor not executable\"" ",\"path\":\"$AUDITOR\""; exit 2
fi

trap 'warn "\"terminating\""; exit 0' INT TERM
info "\"watchdog loop start\"" ",\"interval_sec\":$INTERVAL_SEC"

while :; do
  logf="$LOG_DIR/audit_$(date -u +%Y%m%d_%H%M%S).log"
  if [[ -n "$NODE" ]]; then
    "$AUDITOR" "$NODE" | tee -a "$logf"
  else
    "$AUDITOR" | tee -a "$logf"
  fi
  sleep "$INTERVAL_SEC"
done
