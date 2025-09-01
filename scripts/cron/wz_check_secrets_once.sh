#!/data/data/com.termux/files/usr/bin/sh
# fractal_uuid: $(date -Iseconds)-bootstrap-check-secrets-once
# title: WZ :: One-shot GDrive secrets checker
# version: 1.2.0
# description: Проверяет изменения wz-secrets.kdbx в Google Drive и выводит финальный статус + уведомления.
# updated_at: $(date -Iseconds)

set -Eeuo pipefail

RCLONE_ADDR="127.0.0.1:5572"

# 1) Запуск rclone rcd в фоне (без логов)
rclone rcd --rc --rc-addr=$RCLONE_ADDR --rc-no-auth --quiet &
PID=$!
sleep 2

# 2) Проверка изменений
CHANGES="$(rclone rc backend/command fs=gdrive:WZSecrets command=changes --json '{"dir":""}' 2>/dev/null || true)"

if echo "$CHANGES" | grep -q 'wz-secrets.kdbx'; then
    printf "[WZ-SECRETS] updated\n"
    termux-notification --id wz-secrets --title "WZ Secrets" --content "База обновлена и синхронизирована" >/dev/null 2>&1 || true
    "$HOME/wheelzone-script-utils/scripts/cron/wz_sync_secrets.sh" >/dev/null 2>&1 || {
        printf "[WZ-SECRETS] sync failed\n"
        termux-notification --id wz-secrets --title "WZ Secrets" --content "⚠️ Ошибка при синхронизации" >/dev/null 2>&1 || true
    }
else
    printf "[WZ-SECRETS] clean\n"
fi

# 3) Завершение
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true
