#!/data/data/com.termux/files/usr/bin/bash
# generate_uuid.sh v4.3.0 — WZ Mobile-Optimized UUID Generator (Android 15/HyperOS)
set -euo pipefail
shopt -s nullglob

readonly WZ_LOG_DIR="$HOME/.wz_logs"
readonly WZ_UUID_LOG="$WZ_LOG_DIR/wz_uuid_$(date +%Y%m).ndjson"
readonly SLUG_REGEX='^[a-z0-9\-]{3,64}$'
readonly ANDROID_TMPDIR="/data/data/com.termux/files/usr/tmp"

umask 077
mkdir -p "$WZ_LOG_DIR"
[ -d "$ANDROID_TMPDIR" ] && export TMPDIR="$ANDROID_TMPDIR"

generate_uuid() {
  local hex_chars="0123456789abcdef"
  local uuid=""
  for i in {1..32}; do
    uuid+=${hex_chars:$((RANDOM % 16)):1}
  done
  uuid="${uuid:0:12}4${uuid:13:3}8${uuid:16:3}${uuid:19:12}"
  echo "$uuid"
}

validate_slug() {
  if [[ -n "$1" && ! "$1" =~ $SLUG_REGEX ]]; then
    echo >&2 "[SECURITY] Invalid slug format: '$1'"
    exit 42
  fi
}

safe_log() {
  local json_payload
  json_payload=$(printf '{"time":"%s","uuid":"%s","slug":"%s","v":"4.3.0"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2")
  echo "$json_payload" >> "${WZ_UUID_LOG}.tmp" && mv "${WZ_UUID_LOG}.tmp" "$WZ_UUID_LOG"
}

main() {
  local slug="${1:-}"
  local uuid
  uuid=$(python3 -c 'import uuid; print(uuid.uuid4().hex)' 2>/dev/null || generate_uuid)
  validate_slug "$slug"
  safe_log "$uuid" "$slug"
  echo "$uuid"
}

main "$@"
