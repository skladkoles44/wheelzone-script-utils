# uuid: 2025-08-26T13:20:08+03:00-3043845978
# title: install_dom_pause_handler.sh
# component: .
# updated_at: 2025-08-26T13:20:08+03:00


#!/data/data/com.termux/files/usr/bin/bash

mv ~/storage/downloads/dom_pause_handler.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_pause_handler.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/dom_pause_handler.py
git commit -m "DOM | Добавлена реакция на изменение DOM: лог + установка pause"
git push
