#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:07+03:00-2774801188
# title: install_H_analytics_modules.sh
# component: .
# updated_at: 2025-08-26T13:20:07+03:00


# Перемещение всех новых модулей
mv ~/storage/downloads/vin_pattern_analyzer.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
mv ~/storage/downloads/dom_heatmap_builder.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
mv ~/storage/downloads/auto_penalty_tracker.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
mv ~/storage/downloads/dom_instability_watchdog.py ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/

chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/*.py

# Git фиксация
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main

git add scripts/vin_pattern_analyzer.py scripts/dom_heatmap_builder.py \
        scripts/auto_penalty_tracker.py scripts/dom_instability_watchdog.py
git commit -m "CORE | Установлены модули анализа VIN, DOM Heatmap, AutoPenalty, DOM Watchdog"
git push