#!/data/data/com.termux/files/usr/bin/bash

mv ~/storage/downloads/H_popup_sequence.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/H_popup_sequence.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/H_popup_sequence.py
git commit -m "H_POPUP | Добавлена фаза обработки всплывающего окна на nsis.ru"
git push