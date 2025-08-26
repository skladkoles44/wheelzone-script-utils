# uuid: 2025-08-26T13:20:09+03:00-1438589201
# title: install_vin_validator.sh
# component: .
# updated_at: 2025-08-26T13:20:09+03:00


#!/data/data/com.termux/files/usr/bin/bash

# Переместить
mv ~/storage/downloads/vin_validator.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/vin_validator.py

# Git-фиксация
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/vin_validator.py
git commit -m "VIN_VALIDATOR | Верификация VIN-кодов и флаг vin_confirmed для обучения"
git push
