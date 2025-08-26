# uuid: 2025-08-26T13:20:08+03:00-509636559
# title: install_buffer_domfinger.sh
# component: .
# updated_at: 2025-08-26T13:20:08+03:00


#!/data/data/com.termux/files/usr/bin/bash

# Переместить в scripts/
mv ~/storage/downloads/plate_buffer.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
mv ~/storage/downloads/dom_fingerprint.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/plate_buffer.py
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/dom_fingerprint.py

# Git
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/plate_buffer.py scripts/dom_fingerprint.py
git commit -m "CORE | Добавлены модули plate_buffer и dom_fingerprint для буфера и слежения за DOM"
git push
