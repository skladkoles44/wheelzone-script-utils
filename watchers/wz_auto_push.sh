#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-569745057
# title: wz_auto_push.sh
# component: watchers
# updated_at: 2025-08-26T13:20:17+03:00


# 🔁 Авто-push Git-репозитория WheelZone каждые 10 минут
cd ~/wheelzone || exit

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[WZ-AUTO-PUSH] Обнаружены изменения, выполняется push..."
  git add -A
  git commit -m "auto: periodic push via wz_auto_push.sh"
  git push origin main
else
  echo "[WZ-AUTO-PUSH] Изменений нет."
fi
