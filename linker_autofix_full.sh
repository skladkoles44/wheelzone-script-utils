# uuid: 2025-08-26T13:20:10+03:00-2990708643
# title: linker_autofix_full.sh
# component: .
# updated_at: 2025-08-26T13:20:10+03:00


#!/data/data/com.termux/files/usr/bin/bash

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1

echo "[LINKER] Перемещение файлов..."
mv ~/storage/downloads/plate_profile_linker.py scripts/ 2>/dev/null
mv ~/storage/downloads/linker_loop.sh scripts/ 2>/dev/null
mv ~/storage/downloads/linked_profiles_44.jsonl . 2>/dev/null

chmod +x scripts/linker_loop.sh

echo "[LINKER] Git фиксация..."
git checkout main || git switch main
git pull --rebase origin main
git add scripts/plate_profile_linker.py scripts/linker_loop.sh linked_profiles_44.jsonl
git commit -m "LINKER | Генератор связок госномер–профиль (рег. 44) + автозапуск" && git push

# Автозапуск в bootstrap_tool
echo -e "\n# Auto-launch: plate–profile linker\nbash ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/linker_loop.sh &" >> bootstrap_autorun.sh
chmod +x bootstrap_autorun.sh
echo "[LINKER] Включён автозапуск."

