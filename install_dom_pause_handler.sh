
#!/data/data/com.termux/files/usr/bin/bash

mv ~/storage/downloads/dom_pause_handler.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_pause_handler.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/dom_pause_handler.py
git commit -m "DOM | Добавлена реакция на изменение DOM: лог + установка pause"
git push
