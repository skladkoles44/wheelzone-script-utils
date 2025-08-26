#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:26+03:00-1550907164
# title: fix_logs_ai_gitignore.sh
# component: .
# updated_at: 2025-08-26T13:19:26+03:00

# fix_logs_ai_gitignore.sh — Убирает .gitignore-проблему с logs/ai + логгирует

set -euo pipefail

# === Добавляем правило в .gitignore, если нужно
grep -q '!logs/ai/' "$HOME/wz-wiki/.gitignore" || echo '!logs/ai/' >> "$HOME/wz-wiki/.gitignore"

# === Прописываем защиту во все скрипты
for f in "$HOME/wheelzone-script-utils/scripts/ai"/wz_ai_*.sh; do
  grep -q '!logs/ai/' "$f" || sed -i '1a\
# Ensure logs/ai is not ignored by Git\
grep -q "!logs/ai/" "$HOME/wz-wiki/.gitignore" || echo "!logs/ai/" >> "$HOME/wz-wiki/.gitignore"
' "$f"
done

chmod +x "$HOME"/wheelzone-script-utils/scripts/ai/wz_ai_*.sh

# === Git commit
cd "$HOME/wz-wiki"
git add .gitignore
git commit -m "[Fix] Allow logs/ai directory in Git" || true
git push || echo "[!] Push пропущен"

# === Логирование события
now=$(date -Iseconds)
echo '"fix_logs_ai_gitignore.sh","fix",".gitignore","done","scripts/fixes/fix_logs_ai_gitignore.sh","PUSHED","'"$now"'"' >> "$HOME/wz-wiki/data/script_event_log.csv"
echo '"Fix logs/ai in .gitignore","scripts/fixes/fix_logs_ai_gitignore.sh","'"$now"'","auto-applied"' >> "$HOME/wz-wiki/data/todo_from_chats.csv"

git add data/script_event_log.csv data/todo_from_chats.csv
git commit -m "[Log] Fix logs/ai gitignore registered"
git push || true

echo "[✓] Автофикс завершён"
