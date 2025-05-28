
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
