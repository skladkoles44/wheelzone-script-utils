#!/data/data/com.termux/files/usr/bin/bash

DIGEST="$HOME/storage/downloads/project_44/Termux/Digest/daily_digest_$(date +%Y-%m-%d).md"
TOKEN="7593126254:AAG61-IsOp1H-MaZcGVc2jRBm8WrXMmkYFA"
CHAT_ID="-1002654013714"

if [ ! -f "$DIGEST" ]; then
  curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="⚠️ Digest не найден за $(date +%Y-%m-%d)! Проверь систему."
fi#!/data/data/com.termux/files/usr/bin/bash

# [2025-05-28 00:02] Скрипт создан через newscript()
