#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:07+03:00-193677639
# title: install_H_popup_sequence_final.sh
# component: .
# updated_at: 2025-08-26T13:20:07+03:00


mv ~/storage/downloads/H_popup_sequence.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/H_popup_sequence.py

cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/H_popup_sequence.py
git commit -m "H_POPUP | Обновлена цепочка: ожидание содержимого и закрытие окна"
git push