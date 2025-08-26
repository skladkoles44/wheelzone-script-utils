#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:20+03:00-2341326452
# title: wz_ai_autolog_export.sh
# component: .
# updated_at: 2025-08-26T13:19:20+03:00

# Ensure logs/ai is not ignored by Git
grep -q "!logs/ai/" "$HOME/wz-wiki/.gitignore" || echo "!logs/ai/" >> "$HOME/wz-wiki/.gitignore"
# wz_ai_autolog_export.sh — Экспорт NDJSON логов в GDrive и Git
set -euo pipefail

src="$HOME/.wz_logs/ai"
dst_git="$HOME/wz-wiki/logs/ai"
gdrive_path="gdrive:wz-logs/ai"

mkdir -p "$dst_git"

# Копия в WZGit
cp "$src"/ai_log_*.ndjson "$dst_git/" 2>/dev/null || true
cd "$dst_git"
git add *.ndjson
git commit -m "[Autolog Export] $(date -Iseconds)" || echo "🕊️ Нет новых логов"
git push || echo "⚠️ Git push отложен"

# Копия в GDrive
if rclone listremotes 2>/dev/null | grep -q gdrive:; then
  rclone copy "$src" "$gdrive_path" --update
  echo "[✓] Экспорт в GDrive: $gdrive_path"
else
  echo "[!] GDrive не настроен"
fi

echo "[✓] Экспорт завершён"

# ⬇ Автокоммит
bash ~/wheelzone-script-utils/scripts/autocommit/wz_autocommit.sh "AutoCommit from wz_ai_autolog_export.sh"
