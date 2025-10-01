#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'

say()  { printf "\033[1;92m[WZ] %s\033[0m\n" "$*"; }
warn() { printf "\033[1;93m[WZ] %s\033[0m\n" "$*"; }

PRIMARY_HOST="79.174.85.106"
PRIMARY_PORT=2222
SYNC_BIN="$HOME/wheelzone-script-utils/scripts/sync_tokens.sh"

ssh_up() { # host port
  ssh -q -o BatchMode=yes -o ConnectTimeout=3 -p "$2" "root@$1" "echo ok" 2>/dev/null | grep -q ok
}

queue_count() {
  "$SYNC_BIN" queue 2>/dev/null || echo 0
}

say "VPS status probe:"

# primary
if ssh_up "$PRIMARY_HOST" "$PRIMARY_PORT"; then
  say "primary: $PRIMARY_HOST:$PRIMARY_PORT ONLINE"
else
  warn "primary: $PRIMARY_HOST:$PRIMARY_PORT OFFLINE"
fi

# backup autodetect
mapfile -t DET < <("$SYNC_BIN" detect 2>/dev/null || true)
if [[ ${#DET[@]} -gt 0 ]]; then
  BACK_HOST=$(echo "${DET[0]}" | awk '{print $1}')
  BACK_PORT=$(echo "${DET[0]}" | awk '{print $2}')
  if ssh_up "$BACK_HOST" "$BACK_PORT"; then
    say "backup:  $BACK_HOST:$BACK_PORT ONLINE"
    Q=$(queue_count); say "queue pending: $Q"
    if [[ "$Q" -gt 0 ]]; then
      say "flush queued files → backup"
      WZ_VPS_BACKUP="$BACK_HOST" WZ_VPS_BACKUP_PORT="$BACK_PORT" "$SYNC_BIN" flush || true
    fi
  else
    warn "backup:  $BACK_HOST:$BACK_PORT OFFLINE"
    say "queue pending: $(queue_count)"
  fi
else
  warn "backup:  not detected"
  say  "queue pending: $(queue_count)"
fi
