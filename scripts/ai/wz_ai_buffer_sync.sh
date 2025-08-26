#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:20+03:00-356670401
# title: wz_ai_buffer_sync.sh
# component: .
# updated_at: 2025-08-26T13:19:20+03:00

# wz_ai_buffer_sync.sh — Синхронизация AI-логов + авто-регистрация
set -euo pipefail

src="$HOME/.wz_logs/ai"
dst_git="$HOME/wz-wiki/logs/ai"

mkdir -p "$dst_git"
cp "$src"/ai_log_*.ndjson "$dst_git" 2>/dev/null || true

cd "$dst_git"
git add *.ndjson
git commit -m "[AI-Sync] $(date -Iseconds)" || true
git push || echo "[!] Git push пропущен"

# GDrive (если настроено)
if rclone listremotes 2>/dev/null | grep -q gdrive:; then
  rclone copy "$src" gdrive:wz-logs/ai/ --update
fi

# === Авто-регистрация AI-скриптов (если есть новые) ===
batch_register="$HOME/wheelzone-script-utils/scripts/ai/wz_batch_register_ai.sh"
[[ -x "$batch_register" ]] && bash "$batch_register"

echo "[✓] Логи AI синхронизированы и зарегистрированы"
