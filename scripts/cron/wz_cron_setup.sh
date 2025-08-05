#!/data/data/com.termux/files/usr/bin/bash
# wz_cron_setup.sh — Настройка задач CRON для WheelZone (Android/Termux)
set -euo pipefail

logdir="$HOME/.wz_logs/cron"
mkdir -p "$logdir"

logfile="$logdir/cron_setup_$(date +%Y%m%d_%H%M%S).log"
touch "$logfile"

log() {
  echo "[$(date +%T)] $*" | tee -a "$logfile"
}

crontab_file="$HOME/.termux/tasker-cron.list"
mkdir -p "$(dirname "$crontab_file")"

log "[+] Генерация CRON-списка задач"

cat > "$crontab_file" <<EOF2
*/15 * * * * bash \$HOME/wheelzone-script-utils/scripts/autocommit/wz_autocommit.sh "[CRON] Автокоммит"
*/10 * * * * bash \$HOME/wheelzone-script-utils/scripts/ai/wz_ai_buffer_sync.sh
*/20 * * * * bash \$HOME/wheelzone-script-utils/scripts/rules/wz_sync_rules.sh
EOF2

log "[✓] CRON-список записан: $crontab_file"

# Установка crontab через termux-cron
if command -v crontab >/dev/null 2>&1; then
  crontab "$crontab_file"
  log "[✓] CRONTAB применён"
else
  log "[!] crontab не найден. Добавь в .bashrc автозапуск через at или termux-job"
fi

# Интеграция в CSV
now="$(date -Iseconds)"
mkdir -p "$HOME/wz-wiki/data/"
{
  echo '"wz_cron_setup.sh","cron","setup","active","scripts/cron/wz_cron_setup.sh","PUSHED","'"$now"'"'
  echo '"CRON Tasks Setup","scripts/cron/wz_cron_setup.sh","'"$now"'","cron integration for autocommit, ai buffer, rules sync"'
} >> "$HOME/wz-wiki/data/script_event_log.csv" \
   >> "$HOME/wz-wiki/data/todo_from_chats.csv"

# Git лог
cd "$HOME/wz-wiki"
git add data/script_event_log.csv data/todo_from_chats.csv
git commit -m "[Cron] Setup cron tasks via wz_cron_setup.sh" || true
git push || log "[!] Git push пропущен"

log "[✓] Установка завершена"
