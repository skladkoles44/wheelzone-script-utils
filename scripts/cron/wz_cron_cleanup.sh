#!/data/data/com.termux/files/usr/bin/bash
# удаляет cron-логи старше 30 дней
find "$HOME/.wz_logs/cron" -type f -mtime +30 -delete
