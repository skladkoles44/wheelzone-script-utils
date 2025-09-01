#!/data/data/com.termux/files/usr/bin/sh
# fractal_uuid: $(date -Iseconds)-bootstrap-wz-secrets-watch
# title: WZ :: Secrets Watcher (rclone notify)
# version: 1.0.0
# component: monitoring
# description: Подписка на изменения в gdrive:/WZSecrets, запуск wz_sync_secrets.sh при обновлении wz-secrets.kdbx.
# updated_at: $(date -Iseconds)

set -Eeuo pipefail

say(){ printf "\033[1;92m[WZ-WATCH] %s\033[0m\n" "$*"; }

while true; do
  rclone rc --loop core/notify \\
    fs=gdrive:WZSecrets remote="" events=Create,Update 2>/dev/null | while read -r line; do
      echo "$line" | grep -q 'wz-secrets.kdbx' || continue
      say "Обнаружено обновление wz-secrets.kdbx → запускаем sync"
      ~/wheelzone-script-utils/scripts/cron/wz_sync_secrets.sh || say "❌ sync failed"
    done
  sleep 5
done
