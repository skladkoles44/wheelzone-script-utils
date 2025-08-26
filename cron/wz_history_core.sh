#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:07+03:00-3411172202
# title: wz_history_core.sh
# component: .
# updated_at: 2025-08-26T13:19:07+03:00

# WZ History Core v1.2.1-fractal — fractal UUID + MD5 manifest (Termux, jq fix)
set -eo pipefail

CFG="$HOME/.wz_config/config.env"
[ -f "$CFG" ] && . "$CFG"

: "${SRC_DIR:=$HOME/.wz_history}"
: "${REMOTE:=gdrive:WheelZone/wz-history}"
: "${HASH_ALGO:=md5}"

LOCK="$HOME/.wz_state.lock"
STATE="$HOME/.wz_manifest.md5"
LOG="$HOME/.wz_backup.log"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$SRC_DIR" "${LOCK%/*}" || exit 1

log(){ echo "[$(date '+%F %T')] $*" >> "$LOG"; }

hash_cmd(){
  case "$HASH_ALGO" in
    md5)  command -v md5sum  >/dev/null && echo md5sum  || echo sha256sum ;;
    sha256|*) echo sha256sum ;;
  esac
}

fractal_uuid(){
  local cache="$HOME/.wz_quantum_cache.json"
  if [ -f "$cache" ]; then
    python - <<'PY' 2>/dev/null || true
import json,sys,uuid,os
p=os.path.expanduser("~/.wz_quantum_cache.json")
try:
    with open(p,'r',encoding='utf-8') as f:
        d=json.load(f)
    s=d.get('session_id','').strip()
    if s:
        print(s); sys.exit(0)
except Exception:
    pass
print(uuid.uuid4())
PY
    return
  fi
  if [ -x "$HOME/wheelzone-script-utils/scripts/notion/fractal_logger.py" ]; then
    PYTHONUNBUFFERED=1 python "$HOME/wheelzone-script-utils/scripts/notion/fractal_logger.py" \
      --noop >/dev/null 2>&1 || true
    if [ -f "$cache" ]; then
      python - <<'PY' 2>/dev/null || true
import json,sys,uuid,os
p=os.path.expanduser("~/.wz_quantum_cache.json")
try:
    with open(p,'r',encoding='utf-8') as f:
        d=json.load(f)
    s=d.get('session_id','').strip()
    if s:
        print(s); sys.exit(0)
except Exception:
    pass
print(uuid.uuid4())
PY
      return
    fi
  fi
  python - <<'PY'
import uuid; print(uuid.uuid4())
PY
}

ensure_active_chat(){
  local link="$SRC_DIR/current_session.md"
  local rotate="${1:-0}"
  if [ "$rotate" = "1" ] || [ ! -L "$link" ] || [ ! -f "$link" ]; then
    local u1 ufract fname file
    u1="$(python - <<'PY'
import uuid; print(uuid.uuid4())
PY
)"
    ufract="$(fractal_uuid)"
    fname="$(date +%Y-%m-%d_%H%M%S)_${u1}_chat.md"
    file="$SRC_DIR/$fname"
    {
      echo "---"
      echo "uuid: $u1"
      echo "fractal_uuid: $ufact"
      echo "created_utc: $STAMP"
      echo "format: wz-chat-md/v1"
      echo "---"
      echo
    } > "$file"
    ln -sfn "$file" "$link"
    printf '%s\n' "$file"
  else
    readlink -f "$link"
  fi
}

append_share(){
  local payload="${1:-}"
  local file rotate="${WZ_CHAT_ROTATE:-0}"
  file="$(ensure_active_chat "$rotate")"
  {
    echo '---'
    echo "$STAMP"
    if [ -n "$payload" ]; then
      echo "$payload"
    else
      cat
    fi
  } >> "$file"

  # index.json (UPsert) — FIXED jq filter (added 'if')
  if command -v jq >/dev/null 2>&1; then
    local j="$SRC_DIR/index.json" tmp="$(mktemp)"
    [ -f "$j" ] || echo "[]" > "$j"
    local base msgc
    base="$(basename "$file")"
    msgc="$(grep -c '^---$' "$file" || true)"
    jq --arg f "$base" --arg ts "$STAMP" --argjson mc "${msgc:-0}" '
      if (map(select(.file==$f))|length)==0 then
        . + [{"file":$f,"last_update":$ts,"messages":$mc}]
      else
        map(if .file==$f then .last_update=$ts | .messages=$mc else . end)
      end
    ' "$j" > "$tmp" && mv -f "$tmp" "$j"
  fi
}

do_backup(){
  exec 9>"$LOCK" || exit 0
  flock -n 9 || exit 0

  tmp_manifest="$(mktemp)"
  find "$SRC_DIR" -maxdepth 1 -type f \( -name 'chat_*.md' -o -name 'index.json' -o -name 'current_session.md' -o -name 'manifest.md5' \) -print0 | \
    xargs -0 -P 0 "$(hash_cmd)" > "$tmp_manifest" 2>/dev/null || { rm -f "$tmp_manifest"; flock -u 9; exit 0; }

  [ -s "$tmp_manifest" ] && { [ ! -f "$STATE" ] || ! cmp -s "$STATE" "$tmp_manifest"; } || { rm -f "$tmp_manifest"; flock -u 9; exit 0; }

  snap="snapshots/$(date -u +%Y%m%dT%H%M%SZ)"
  rclone sync "$SRC_DIR" "$REMOTE/current" --fast-list --transfers 2 --log-level ERROR &>> "$LOG"
  rclone copy "$SRC_DIR" "$REMOTE/$snap"   --fast-list --log-level ERROR &>> "$LOG"

  mv -f "$tmp_manifest" "$STATE"
  flock -u 9
  log "OK backup -> $REMOTE/$snap"
}

main(){
  case "${1:-}" in
    --share)  shift; append_share "${1:-}"; nohup bash "$0" --backup >/dev/null 2>&1 & ;;
    --rotate) shift; WZ_CHAT_ROTATE=1 append_share "${1:-}"; nohup bash "$0" --backup >/dev/null 2>&1 & ;;
    --backup) do_backup ;;
    *)        if [ -n "${1:-}" ]; then
                "$0" --share "$1"
              else
                content="$(cat || true)"; "$0" --share "$content"
              fi
              ;;
  esac
}
main "$@"
