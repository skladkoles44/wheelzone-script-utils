#!/data/data/com.termux/files/usr/bin/bash
# WZ Notify v10.0.0 — Fractal Logging (Loki/FractalDB Edition)
set -eo pipefail
IFS=$'\n\t'

### CONFIGURATION ###
declare -A CONF=(
  [VERSION]="10.0.0"
  [SCHEMA]="fractal2025"
  [MAX_RETRIES]=3
  [RETRY_DELAY]=1
  [TIMEOUT]=5
)

### PATHS ###
declare -A PATHS=(
  [LOKI_SCRIPT]="$HOME/wheelzone-script-utils/scripts/logging/wz_log_event_loki.sh"
  [FRACTAL_LOGGER]="$HOME/.local/bin/fractal_logger.py"
  [CACHE_DIR]="$HOME/.cache/wz_notify"
  [KEY_FILE]="$HOME/.config/wz_notify.key"
  [LOCK_FILE]="/tmp/wz_notify.lock"
  [LOG_FILE]="$HOME/.local/var/log/wz_notify.log"
)

mkdir -p "${PATHS[CACHE_DIR]}" "$(dirname "${PATHS[LOG_FILE]}")"

### ENCRYPTION ###
gen_id() {
  (date +%s%N; cat /proc/sys/kernel/random/uuid; head -c 256 /dev/urandom) |
  sha512sum | base64 | head -c 64
}

ensure_key() {
  [[ -f "${PATHS[KEY_FILE]}" ]] || {
    openssl rand -hex 64 > "${PATHS[KEY_FILE]}"
    chmod 400 "${PATHS[KEY_FILE]}"
  }
}

encrypt() {
  ensure_key
  openssl enc -aes-256-gcm -md sha512 -a -salt -pass file:"${PATHS[KEY_FILE]}" 2>/dev/null
}

### PAYLOAD ###
build_payload() {
  local -n a=$1
  jq -n --arg id "$(gen_id)" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
        --arg schema "${CONF[SCHEMA]}" \
        --arg ver "${CONF[VERSION]}" \
        --arg type "${a[type]}" \
        --arg title "${a[title]}" \
        --arg desc "${a[desc]}" \
        --arg tag "${a[tag]}" \
        --arg status "${a[status]}" \
        --arg src "${a[source]}" '
    {
      meta: {
        id: $id,
        timestamp: $ts,
        schema: $schema,
        version: $ver
      },
      event: {
        type: $type,
        title: $title,
        description: $desc,
        tag: $tag,
        status: $status,
        source: $src
      }
    }'
}

### DELIVERY ###
send_payload() {
  local channel="$1" data="$2"
  case "$channel" in
    loki)
      [[ -x "${PATHS[LOKI_SCRIPT]}" ]] && echo "$data" | timeout ${CONF[TIMEOUT]} "${PATHS[LOKI_SCRIPT]}" --stdin
      ;;
    fractal)
      [[ -x "${PATHS[FRACTAL_LOGGER]}" ]] && echo "$data" | timeout ${CONF[TIMEOUT]} python3 "${PATHS[FRACTAL_LOGGER]}" --stdin
      ;;
  esac
}

try_delivery() {
  local payload="$1"
  for channel in loki fractal; do
    for ((i=0;i<${CONF[MAX_RETRIES]};i++)); do
      if send_payload "$channel" "$payload"; then
        echo "[OK] $channel accepted payload" >> "${PATHS[LOG_FILE]}"
        return 0
      fi
      sleep ${CONF[RETRY_DELAY]}
    done
  done
  return 1
}

cache_fail() {
  local payload="$1"
  local file="${PATHS[CACHE_DIR]}/$(date +%s.%N).enc"
  encrypt <<< "$payload" > "$file"
  echo "[CACHE] Payload saved: $file" >> "${PATHS[LOG_FILE]}"
}

### ARGUMENTS ###
parse_args() {
  declare -A args=(
    [type]="system"
    [title]="Untitled"
    [desc]="No description"
    [tag]="infra"
    [status]="PUSHED"
    [source]="Termux"
  )

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type|--title|--desc|--tag|--status|--source)
        args["${1#--}"]="$2"; shift 2;;
      --stdin)
        cat - ;;  # passthrough mode
      *)
        echo "[ERR] Unknown arg: $1" >&2; exit 1;;
    esac
  done

  declare -p args
}

### MAIN ###
main() {
  eval "declare -A args=$(parse_args "$@")"
  local payload
  payload="$(build_payload args)"

  (
    flock -x 200 || exit 1
    if ! try_delivery "$payload"; then
      cache_fail "$payload"
    fi
  ) 200>"${PATHS[LOCK_FILE]}"
}

main "$@"
