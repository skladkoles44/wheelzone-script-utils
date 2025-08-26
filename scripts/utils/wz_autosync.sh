#!/bin/bash
# uuid: 2025-08-26T13:19:41+03:00-149695562
# title: wz_autosync.sh
# component: .
# updated_at: 2025-08-26T13:19:41+03:00

set -euo pipefail

# === Настройки ===
WATCH_DIRS=("$HOME/wheelzone-script-utils" "$HOME/wz-wiki")
SERVER_HOST="79.174.85.106"
SERVER_PORT=2222
SERVER_USER="root"
SERVER_REPO_DIR_WIKI="~/wz-wiki"
SERVER_REPO_DIR_SCRIPTS="~/wheelzone-script-utils"
BRANCH="main"

sync_repo() {
    local repo_dir="$1"
    echo "📤 Синхронизация $repo_dir..."
    cd "$repo_dir"
    git add -A
    git commit -m "autosync: $(basename "$repo_dir") $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || true
    git push origin "$BRANCH"
}

sync_server() {
    echo "📥 Пулл на сервере ${SERVER_HOST}:${SERVER_PORT}..."
    ssh -p "$SERVER_PORT" "${SERVER_USER}@${SERVER_HOST}" "
        cd ${SERVER_REPO_DIR_WIKI} && git pull --ff-only
        cd ${SERVER_REPO_DIR_SCRIPTS} && git pull --ff-only
    "
}

echo "🚀 Авто-синк запущен. Отслеживаются каталоги: ${WATCH_DIRS[*]}"
command -v inotifywait >/dev/null 2>&1 || { echo "Установите inotify-tools"; exit 1; }

inotifywait -m -r -e modify,create,delete,move "${WATCH_DIRS[@]}" |
while read -r dir event file; do
    echo "🔄 Изменение: $dir$file ($event)"
    if [[ "$dir" == *"wz-wiki"* ]]; then
        sync_repo "$HOME/wz-wiki"
    elif [[ "$dir" == *"wheelzone-script-utils"* ]]; then
        sync_repo "$HOME/wheelzone-script-utils"
    fi
    sync_server
done
