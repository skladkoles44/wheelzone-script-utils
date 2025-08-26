#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:25+03:00-1324598217
# title: wz_cron_daemon.sh
# component: .
# updated_at: 2025-08-26T13:19:25+03:00

# wz_cron_daemon.sh — Псевдо-cron для Termux (WZ-style)
set -euo pipefail
shopt -s nullglob

logdir="$HOME/.wz_logs/cron"
mkdir -p "$logdir"
logf="$logdir/cron_runtime_$(date +%Y%m%d).log"

while true; do
  date "+[%F %T] ⏰ Tick" >> "$logf"
  awk -v nowmin="$(date +%M)" -v nowhr="$(date +%H)" '
    $0 ~ /^[0-9]/ {
      split($1, m, "/")
      split($2, h, "/")
      if ((nowmin % m[2]) == 0 && (nowhr % h[2]) == 0) print $0
    }
  ' "$HOME/.termux/cronjobs/jobs.list" | while read -r cronjob; do
    cmd="${cronjob#* * * * * }"
    bash -c "$cmd" >> "$logf" 2>&1
  done
  sleep 60
done

# --- [SYNC] Обновление cron-файла каждые 6 часов ---
if (( $(date +%H) % 6 == 0 )) && [[ "$(date +%M)" -lt 2 ]]; then
  echo "[⏳] Синхронизация CRON-файла (6ч)" | tee -a "$logfile"
  bash ~/wheelzone-script-utils/scripts/cron/wz_sync_cron_list.sh || echo "[!] Sync failed"
fi
