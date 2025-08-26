#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-1311199903
# title: watch_inbox (1).sh
# component: .
# updated_at: 2025-08-26T13:20:17+03:00


SOURCE_DIR="$HOME/storage/shared/Projects/wheelzone/bootstrap_tool"
DEST_REMOTE="yadisk_creator:lllBackUplll-WheelZone"
LOGFILE="$HOME/storage/shared/Projects/wheelzone/logs/rclone_backup.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] === Start Rclone Sync ===" >> "$LOGFILE"
/data/data/com.termux/files/usr/bin/rclone sync "$SOURCE_DIR" "$DEST_REMOTE" --create-empty-src-dirs --log-level INFO --log-file="$LOGFILE"
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "[$TIMESTAMP] Rclone completed successfully." >> "$LOGFILE"
else
    echo "[$TIMESTAMP] Rclone FAILED with status $STATUS" >> "$LOGFILE"
    # Место для уведомления (телеграм-бот, звук, всплывающее уведомление и т.д.)
    termux-notification --title "Rclone ERROR" --content "Backup failed at $TIMESTAMP"
fi

echo "[$TIMESTAMP] === End Rclone Sync ===" >> "$LOGFILE"