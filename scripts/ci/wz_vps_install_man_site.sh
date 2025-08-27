#!/usr/bin/env bash
set -Eeuo pipefail
VPS_HOST="${VPS_HOST:-root@79.174.85.106}"
VPS_PORT="${VPS_PORT:-2222}"
SITE_ROOT="${VPS_DEST:-/var/www/wz-manpages}"
SERVER_NAME="${SERVER_NAME:-wz-manpages.local}"
SSH_OPTS="-p ${VPS_PORT} -o ConnectTimeout=6 -o StrictHostKeyChecking=accept-new"

read -r -d '' NGINX_CONF <<'NGX'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/wz-manpages.access.log;
    error_log  /var/log/nginx/wz-manpages.error.log;

    root /var/www/wz-manpages;
    autoindex on;

    location / {
        add_header Cache-Control "public, max-age=60";
        try_files $uri =404;
    }

    # .sha256 текстом
    types { text/plain sha256; }
    gzip on;
    gzip_types text/plain application/json text/css application/javascript;
}
NGX

ssh $SSH_OPTS "$VPS_HOST" "bash -se" <<EOS
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx rsync
mkdir -p "$SITE_ROOT"
chown -R www-data:www-data "$SITE_ROOT"
echo "$NGINX_CONF" > /etc/nginx/sites-available/wz-manpages.conf
ln -sf /etc/nginx/sites-available/wz-manpages.conf /etc/nginx/sites-enabled/wz-manpages.conf
nginx -t
systemctl enable --now nginx
systemctl reload nginx
echo "[WZ] Nginx configured → $SITE_ROOT"
EOS

# Первичная синхронизация артефактов
SRC="$HOME/wheelzone-script-utils/docs/artifacts/"
rsync -az -e "ssh $SSH_OPTS" "$SRC" "$VPS_HOST:$SITE_ROOT/"
echo "[WZ] Synced artifacts to VPS: $VPS_HOST:$SITE_ROOT"
