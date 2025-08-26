#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:21+03:00-1785455366
# title: wz_autocommit.sh
# component: .
# updated_at: 2025-08-26T13:19:21+03:00

# wz_autocommit.sh — Автокоммит с поддержкой CRON, WZDrone, WZ Noiton
set -euo pipefail

# === Конфигурация ===
git_dir="${2:-$HOME/wz-wiki}"
now=$(date -Iseconds)
msg="${1:-[Auto] Коммит от $now}"
log_csv="$git_dir/data/script_event_log.csv"
todo_csv="$git_dir/data/todo_from_chats.csv"
logfile="$HOME/.wz_logs/autocommit_$(date +%Y%m%d).log"
wzlog_py="$HOME/wheelzone-script-utils/scripts/notion/fractal_logger.py"

# === Проверка изменений ===
cd "$git_dir"
if git diff-index --quiet HEAD --; then
  echo "[✓] Нет изменений для коммита" | tee -a "$logfile"
  [[ "${3:-}" == "--cron" ]] && exit 11
  exit 0
fi

# === CSV логирование ===
echo "\"$msg\",\"auto\",\"commit\",\"active\",\"scripts/autocommit/wz_autocommit.sh\",\"PUSHED\",\"$now\"" >> "$log_csv"
echo "\"$msg\",\"scripts/autocommit/wz_autocommit.sh\",\"$now\",\"auto-pushed\"" >> "$todo_csv"

# === Git commit/push ===
git add .
git commit -m "$msg" || echo "[!] Коммит без новых изменений" | tee -a "$logfile"
git push || echo "[!] Push не выполнен" | tee -a "$logfile"

echo "[✓] Автокоммит завершён: $msg" | tee -a "$logfile"

# === WZ Noiton логирование ===
if [ -f "$wzlog_py" ] && [ -f "$HOME/.env.wzbot" ]; then
  python3 "$wzlog_py" \
    --type "core" \
    --title "$msg" \
    --source "wz_autocommit.sh" \
    --status "pushed" \
    --time "$now" \
    >> "$logfile" 2>&1 || echo "[!] Ошибка WZ Noiton логгера" >> "$logfile"
fi

exit 0
