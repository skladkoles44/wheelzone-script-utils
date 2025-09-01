#!/usr/bin/env bash
# uuid: $(date -Iseconds)-sync-tokens
# title: WZ :: Token sync (local→VPS+cloud) with offline queue + detect
# version: 1.3.0
# updated_at: $(date -Iseconds)
set -Eeuo pipefail; IFS=$'\n\t'

say(){ printf "\033[1;92m[WZ] %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;93m[WZ] %s\033[0m\n" "$*"; }
err(){ printf "\033[1;31m[WZ] ERROR: %s\033[0m\n" "$*" >&2; }

PRIMARY_IP="79.174.85.106"
PRIMARY_PORT=2222
DEFAULT_PORT=2222

LOGDIR="${LOGDIR:-$HOME/wzbuffer}"
SPOOLDIR="${SPOOLDIR:-$HOME/wzbuffer/spool}"
BACKUP_QUEUE="$SPOOLDIR/backup_pending"
mkdir -p "$LOGDIR" "$BACKUP_QUEUE"

ssh_copy() { # host port file -> 0/1
  local host="$1" port="$2" file="$3"
  scp -P "$port" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=5 \
      -o ServerAliveInterval=10 \
      -o ServerAliveCountMax=3 \
      "$file" "root@${host}:/root/" >/dev/null 2>&1
}

queue_backup() { # file -> enqueue
  local f="$1" base; base="$(basename "$f")"
  cp -f "$f" "$BACKUP_QUEUE/$base"
  say "queued for backup: $base"
}

find_latest_token_file() {
  local dirs=("$LOGDIR" "$HOME/wzbuffer" "$HOME/storage/downloads" "$PWD")
  local seen=() d
  for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    case " ${seen[*]} " in *" $d "*) ;; *) seen+=("$d");; esac
  done
  local cand=""
  for d in "${seen[@]}"; do
    cand=$(ls -1t "$d"/wz_token_login_*.txt.gpg 2>/dev/null | head -n1 || true)
    [ -n "$cand" ] && { printf '%s\n' "$cand"; return 0; }
  done
  return 1
}

flush_queue_if_any() {
  local host="$1" port="$2"
  shopt -s nullglob
  local files=("$BACKUP_QUEUE"/*.gpg)
  [ ${#files[@]} -eq 0 ] && { say "queue empty"; return 0; }
  say "flushing queue → ${host}:${port} (${#files[@]} files)"
  local ok=0 fail=0 f
  for f in "${files[@]}"; do
    if ssh_copy "$host" "$port" "$f"; then
      rm -f "$f"; ok=$((ok+1))
    else
      fail=$((fail+1))
    fi
  done
  say "queue result: sent=$ok pending=$fail"
}

queue_count() {
  [ -d "$BACKUP_QUEUE" ] || { echo 0; return; }
  find "$BACKUP_QUEUE" -type f -name '*.gpg' 2>/dev/null | wc -l
}

detect_backup() {
  # Если задан вручную — отдадим его
  if [[ -n "${WZ_VPS_BACKUP:-}" ]]; then
    printf "%s %s\n" "$WZ_VPS_BACKUP" "${WZ_VPS_BACKUP_PORT:-$DEFAULT_PORT}"
    return 0
  fi
  # Скан стартовых файлов/баннеров
  local files=(
    "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"
    "$HOME/.termux/termux.properties" "$HOME/.termux/shellrc" "$HOME/.termux/"*
    "$HOME/"*menu* "$HOME/"*motd* "$HOME/wzbuffer/"*menu* "$HOME/wzbuffer/"*motd*
  )
  local blob; blob=$(cat ${files[@]} 2>/dev/null || true)
  local lines; lines=$(printf "%s\n" "$blob" | grep -Ei "yellow|backup|впс|vps|hydrogen|резерв" -n || true)
  [ -n "$lines" ] || lines="$blob"

  local host="" port=""
  # HOST:PORT
  if [[ -z "$host" ]]; then
    host=$(printf "%s\n" "$lines" | grep -Eo '([A-Za-z0-9.-]+):([0-9]{2,5})' | awk -F: '{print $1}' | grep -v "$PRIMARY_IP" | head -n1 || true)
    port=$(printf "%s\n" "$lines" | grep -Eo '([A-Za-z0-9.-]+):([0-9]{2,5})' | awk -F: '{print $2}' | head -n1 || true)
  fi
  # ssh -p PORT ... @HOST
  if [[ -z "$host" ]]; then
    host=$(printf "%s\n" "$lines" | grep -Eo '@([A-Za-z0-9.-]+)' | tr -d '@' | grep -v "$PRIMARY_IP" | head -n1 || true)
    port=$(printf "%s\n" "$lines" | grep -Eo '(-p[[:space:]]+|--port[[:space:]]+)([0-9]{2,5})' | awk '{print $2}' | head -n1 || true)
  fi
  # просто HOST
  if [[ -z "$host" ]]; then
    host=$(printf "%s\n" "$lines" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|[A-Za-z0-9.-]+' \
      | grep -vE '^(ssh|root|localhost|127\.0\.0\.1|'"$PRIMARY_IP"')$' | head -n1 || true)
  fi
  [[ -n "$port" ]] || port="$DEFAULT_PORT"

  if [[ -n "$host" && "$host" != "$PRIMARY_IP" ]]; then
    printf "%s %s\n" "$host" "$port"
    return 0
  fi
  return 1
}

# ── CLI ───────────────────────────────────────────────────────────────────────
MODE="${1:-sync}" # sync | flush | detect | queue
case "$MODE" in
  detect)
    detect_backup || exit 1
    exit 0
    ;;
  queue)
    queue_count
    exit 0
    ;;
  flush)
    mapfile -t DET < <(detect_backup || true)
    [[ ${#DET[@]} -gt 0 ]] || { err "backup not detected"; exit 1; }
    B_HOST=$(echo "${DET[0]}" | awk '{print $1}')
    B_PORT=$(echo "${DET[0]}" | awk '{print $2}')
    flush_queue_if_any "$B_HOST" "$B_PORT"
    exit 0
    ;;
  sync) :;;
  *) err "unknown mode: $MODE"; exit 2;;
esac

# ── основной sync ─────────────────────────────────────────────────────────────
say "lookup in: $LOGDIR
$HOME/wzbuffer
$HOME/storage/downloads
$PWD"
LATEST="$(find_latest_token_file || true)"
[ -n "$LATEST" ] || { err "no token file found (wz_token_login_*.txt.gpg)"; exit 1; }
say "found: $LATEST"

# primary
say "syncing → primary ${PRIMARY_IP}:${PRIMARY_PORT}"
ssh_copy "$PRIMARY_IP" "$PRIMARY_PORT" "$LATEST" || warn "primary copy failed"

# backup
mapfile -t DET < <(detect_backup || true)
if [[ ${#DET[@]} -gt 0 ]]; then
  B_HOST=$(echo "${DET[0]}" | awk '{print $1}')
  B_PORT=$(echo "${DET[0]}" | awk '{print $2}')
  say "syncing → backup ${B_HOST}:${B_PORT}"
  if ssh_copy "$B_HOST" "$B_PORT" "$LATEST"; then
    say "backup: sent"
    flush_queue_if_any "$B_HOST" "$B_PORT"
  else
    warn "backup offline → enqueue"
    queue_backup "$LATEST"
  fi
else
  warn "backup not detected → skip"
fi

# clouds
if command -v rclone >/dev/null 2>&1; then
  rclone copy "$LATEST" gdrive:/wz-secrets/ 2>/dev/null || warn "gdrive copy failed"
  rclone copy "$LATEST" yandex:/wz-secrets/ 2>/dev/null || warn "yandex copy failed"
else
  warn "rclone not found → cloud skip"
fi

say "done"
