#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:11+03:00-3912209982
# title: proxy_watch.sh
# component: .
# updated_at: 2025-08-26T13:20:11+03:00


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
