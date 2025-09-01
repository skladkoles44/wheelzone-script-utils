#!/usr/bin/env bash
set -Eeuo pipefail
VPS_HOST="${VPS_HOST:-root@79.174.85.106}"
VPS_PORT="${VPS_PORT:-2222}"
VPS_DEST="${VPS_DEST:-/var/www/wz-manpages}"
SSH_OPTS="-p $VPS_PORT -o ConnectTimeout=6 -o StrictHostKeyChecking=accept-new"

SRC_DIR="$HOME/wheelzone-script-utils/docs/artifacts"

# Пингуем порт SSH
if ! timeout 6 bash -c "cat < /dev/null >/dev/tcp/$(echo "$VPS_HOST" | sed 's/.*@//')/$VPS_PORT" 2>/dev/null; then
  echo "[WZ] VPS недоступен: $VPS_HOST:$VPS_PORT — пропускаю публикацию"
  exit 0
fi

# Создаём папку и синкаем
ssh $SSH_OPTS "$VPS_HOST" "mkdir -p '$VPS_DEST'"
rsync -az -e "ssh $SSH_OPTS" "$SRC_DIR/" "$VPS_HOST:$VPS_DEST/"

echo "[WZ] VPS updated: $VPS_HOST:$VPS_DEST"
