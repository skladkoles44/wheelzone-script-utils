#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:09+03:00-587452158
# title: install_unstable_logger.sh
# component: .
# updated_at: 2025-08-26T13:20:09+03:00


# Переместить скрипт
mv ~/storage/downloads/unstable_logger.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/unstable_logger.py

# Git фиксация
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/unstable_logger.py
git commit -m "LOG | Добавлен логгер нестабильных попыток unstable_logger.py"
git push