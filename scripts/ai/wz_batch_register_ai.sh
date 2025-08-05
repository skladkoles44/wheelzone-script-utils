#!/data/data/com.termux/files/usr/bin/bash
# wz_batch_register_ai.sh — Регистрация AI-логов в CSV-реестрах
set -euo pipefail

log="$HOME/.wz_logs/ai"
csv="$HOME/wz-wiki/data/script_event_log.csv"
todo="$HOME/wz-wiki/data/todo_from_chats.csv"
mkdir -p "$(dirname "$csv")"

today="$(date +%Y%m%d)"
now="$(date -Iseconds)"
file="$log/ai_log_${today}.ndjson"

grep -F '"uuid"' "$file" | while read -r line; do
  uuid="$(jq -r '.uuid' <<< "$line")"
  label="$(jq -r '.label' <<< "$line")"
  type="$(jq -r '.type' <<< "$line")"
  echo "\"$uuid\",\"ai\",\"$type\",\"active\",\"logs/ai/ai_log_${today}.ndjson\",\"PUSHED\",\"$now\"" >> "$csv"
  echo "\"[AI] $label\",\"logs/ai/ai_log_${today}.ndjson\",\"$now\",\"review & tag\"" >> "$todo"
done

cd "$HOME/wz-wiki"
git add "$csv" "$todo"
git commit -m "[AI-Log] Auto-register logs $today" || true
git push || echo "[!] Git push failed"
