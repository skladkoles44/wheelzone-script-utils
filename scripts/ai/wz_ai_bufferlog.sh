#!/data/data/com.termux/files/usr/bin/bash
# Ensure logs/ai is not ignored by Git
grep -q "!logs/ai/" "$HOME/wz-wiki/.gitignore" || echo "!logs/ai/" >> "$HOME/wz-wiki/.gitignore"
set -euo pipefail
logdir="$HOME/.wz_logs/ai"
uuid=$(uuidgen | tr 'A-Z' 'a-z')
ts=$(date -Iseconds)
echo "{\"uuid\":\"$uuid\",\"time\":\"$ts\",\"log\":\"$*\"}" >> "$logdir/ai_log_$(date +%Y%m%d).ndjson"
echo "[✓] Лог сохранён: $uuid"
