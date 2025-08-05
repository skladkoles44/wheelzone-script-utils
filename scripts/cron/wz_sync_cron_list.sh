#!/data/data/com.termux/files/usr/bin/bash
# wz_sync_cron_list.sh — копирует CRON-список в Git и пушит
set -euo pipefail

src="$HOME/.termux/tasker-cron.list"
dst="$HOME/wz-wiki/data/tasker-cron.list"

cp "$src" "$dst" || exit 1

cd "$HOME/wz-wiki"
git add "data/tasker-cron.list"
git commit -m "[CRON] Sync cron.list at $(date +%Y-%m-%dT%H:%M:%S)" || true
git push || echo "[!] Git push failed"

# Автоуведомление
bash ~/wheelzone-script-utils/scripts/notify/wz_notify.sh --title "CRON Sync" --message "Список CRON задач сохранён и запушен" --type "script-event" --source "wz_sync_cron_list.sh"
