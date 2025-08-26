#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:25+03:00-2643117680
# title: wz_cron_cleanup.sh
# component: .
# updated_at: 2025-08-26T13:19:25+03:00

# удаляет cron-логи старше 30 дней
find "$HOME/.wz_logs/cron" -type f -mtime +30 -delete
