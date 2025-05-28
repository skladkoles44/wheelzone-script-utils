#!/data/data/com.termux/files/usr/bin/bash

BOT_TOKEN="7593126254:AAG61-IsOp1H-MaZcGVc2jRBm8WrXMmkYFA"
CHAT_ID="-1001975043439"
MESSAGE="✅ Успешный Push: изменения загружены в Git, Drive и Яндекс.Диск"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE"

