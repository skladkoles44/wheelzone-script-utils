#!/data/data/com.termux/files/usr/bin/bash

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