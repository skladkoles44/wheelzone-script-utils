
#!/data/data/com.termux/files/usr/bin/bash

LOG=~/storage/shared/Projects/wheelzone/bootstrap_tool/logs/linker_log.md
echo "[linker_loop] Активен: $(date)" >> $LOG

while true; do
  python3 ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/plate_profile_linker.py >> $LOG 2>&1
  sleep 10
done
