#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:20+03:00-3516063686
# title: yadisk_autopull.sh
# component: .
# updated_at: 2025-08-26T13:20:20+03:00

export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:$PATH

# Путь к репо
cd ~/wheelzone/bootstrap_tool/

# Синхронизация из Яндекс.Диска
rclone copy yadisk_creator:BackUp ./ --create-empty-src-dirs --progress

# Git фиксация
git add .
git diff --cached --quiet || (
  git commit -m "Авто-забор из BackUp и push в Git"
  git push origin main
)
