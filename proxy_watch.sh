#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR=~/storage/downloads/project_44/Termux
STAMP=$(date +"%Y%m%d_%H%M%S")
OUTFILE="$LOG_DIR/net_log_$STAMP.txt"

echo "Лог сетевых подключений — $STAMP" > "$OUTFILE"
echo "Нажми Ctrl+C для остановки" >> "$OUTFILE"

while true; do
    echo -e "\n--- $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$OUTFILE"
    ss -tulnp >> "$OUTFILE" 2>&1
    sleep 10
done
