# uuid: 2025-08-26T13:20:06+03:00-3907787373
# title: insightcore_watchdog.sh
# component: .
# updated_at: 2025-08-26T13:20:07+03:00


#!/data/data/com.termux/files/usr/bin/bash

LOG=~/storage/shared/Projects/wheelzone/bootstrap_tool/logs/insightcore_activity.log
echo "[Watchdog] Запуск InsightCore: $(date)" >> $LOG

while true; do
  python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/H_InsightCore.py >> $LOG 2>&1
  sleep 30
done
