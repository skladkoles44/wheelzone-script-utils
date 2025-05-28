
#!/data/data/com.termux/files/usr/bin/bash

mv ~/storage/downloads/trap_input_sim.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/trap_input_sim.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/trap_input_sim.py
git commit -m "SHIELD_SIM | Модуль ловушек активен: trap_input_sim"
git push
