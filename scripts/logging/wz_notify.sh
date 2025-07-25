#!/data/data/com.termux/files/usr/bin/bash
# WZ Notify v3.2.1 — Optimized Loki Edition (HyperOS-Termux Ready)

set -eo pipefail
IFS=$'\n\t'
trap 'echo "🛑 [wz_notify.sh] CRASHED in line $LINENO | Args: $*" >&2' ERR

declare -A VALID_STATUSES=(
  ["info"]=1
  ["warn"]=1
  ["error"]=1
  ["critical"]=1
)
declare -r MAX_SOURCE_LEN=64

main() {
  local TYPE TITLE DESC STATUS="info" SOURCE="wz_notify.sh"
  
  parse_args "$@"
  validate_inputs || die "Validation failed"
  send_notification || die "Notification failed"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --type)   TYPE="${2:-}";   shift 2 ;;
      --title)  TITLE="${2:-}";  shift 2 ;;
      --desc)   DESC="${2:-}";   shift 2 ;;
      --status) STATUS="${2,,}"; shift 2 ;;
      --source) SOURCE="${2:-wz_notify.sh}"; shift 2 ;;
      *) die "Invalid argument: $1" ;;
    esac
  done
}

validate_inputs() {
  [[ -z "${TYPE:-}" || -z "${TITLE:-}" ]] && return 1
  [[ -z "${VALID_STATUSES[${STATUS:-info}]+isset}" ]] && STATUS="info"
  SOURCE=$(sed 's/[^[:alnum:]_-]//g' <<< "${SOURCE:0:$MAX_SOURCE_LEN}")
  return 0
}

send_notification() {
  local -r LOKI_LOGGER="$HOME/wheelzone-script-utils/scripts/logging/wz_log_event_loki.sh"
  local -r MESSAGE="[${TYPE}][${STATUS}] ${TITLE}${DESC:+: ${DESC}} (source: ${SOURCE})"
  
  [[ -x "$LOKI_LOGGER" ]] || return 1
  "$LOKI_LOGGER" "$STATUS" "$MESSAGE" || return 1
}

die() { 
  echo "❌ ERROR: $1" >&2 
  exit 1
}

main "$@"
