
#!/data/data/com.termux/files/usr/bin/bash

echo "[FIX] Перемещаем attach_result_to_profile.py..."
mv ~/storage/downloads/attach_result_to_profile.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/attach_result_to_profile.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/attach_result_to_profile.py
git commit -m "LINKER | Добавлен модуль привязки VIN к связке госномер–профиль"
git push
