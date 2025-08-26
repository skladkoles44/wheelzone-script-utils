#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:18+03:00-1827002110
# title: wz_notify_push.sh
# component: .
# updated_at: 2025-08-26T13:20:18+03:00

[ -f ~/wheelzone/secrets/tokens.env ] && source ~/wheelzone/secrets/tokens.env
CHAT_ID="-1001975043439"
MESSAGE="✅ Успешный Push: изменения загружены в Git, Drive и Яндекс.Диск"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE"

