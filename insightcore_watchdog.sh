
#!/data/data/com.termux/files/usr/bin/bash

LOG=~/storage/shared/Projects/wheelzone/bootstrap_tool/logs/insightcore_activity.log
echo "[Watchdog] Запуск InsightCore: $(date)" >> $LOG

while true; do
  python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/H_InsightCore.py >> $LOG 2>&1
  sleep 30
done
