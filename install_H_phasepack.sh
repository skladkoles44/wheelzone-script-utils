#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:07+03:00-1351829593
# title: install_H_phasepack.sh
# component: .
# updated_at: 2025-08-26T13:20:07+03:00


# Переместить все скрипты фаз
for script in linked_profiles_validator.py plate_retry_manager.py fingerprint_rotator.py dom_fragment_indexer.py personality_history_tracker.py; do
  mv ~/storage/downloads/$script ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
  chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/$script
done

# Git фиксация
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/linked_profiles_validator.py scripts/plate_retry_manager.py \
        scripts/fingerprint_rotator.py scripts/dom_fragment_indexer.py \
        scripts/personality_history_tracker.py

git commit -m "PHASEPACK | Внедрены аналитические фазы: VIN Validate, Retry, Rotator, DOM Indexer, History Tracker"
git push