#!/usr/bin/env bash
# WZ Health Triage v1.0 — безопасная остановка флаппинга + сбор фактов
set -euo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${HOME}/wzbuffer"
REPORT="${OUT_DIR}/wz_health_triage_${TS}.txt"

say(){ printf "\n=== %s ===\n" "$*" | tee -a "$REPORT"; }
run(){ echo "\n$ $*" | tee -a "$REPORT"; (eval "$@" 2>&1 | tee -a "$REPORT") || true; }

mkdir -p "$OUT_DIR"
: > "$REPORT"

say "1) Поиск и остановка таймера/крона для wz-api-healthalert"
run "systemctl list-timers --all | grep -E 'wz-api-healthalert|wz.*health' || true"
# Если есть таймер — аккуратно притормозим
if systemctl list-timers --all | grep -q 'wz-api-healthalert.timer'; then
  run "sudo systemctl stop wz-api-healthalert.timer"
  run "sudo systemctl disable wz-api-healthalert.timer"
fi
# На всякий случай глушим сам сервис (если стартовал)
run "sudo systemctl stop wz-api-healthalert.service || true"

say "2) Статусы проблемных юнитов (healthalert / conv-clean / logdigest)"
for u in wz-api-healthalert.service wz-conv-clean.service wz-logdigest.service; do
  run "echo '--- status: ${u} ---'"
  run "systemctl status ${u} --no-pager || true"
  run "journalctl -u ${u} --since '36 hours ago' -n 200 --no-pager || true"
done

say "3) Loki/Promtail проверка"
run "systemctl status loki || true"
run "systemctl status promtail || true"
run "ss -lntp | grep -E ':3100\\b' || true"
run "curl -sS http://127.0.0.1:3100/ready || true"
run "curl -sS http://127.0.0.1:3100/metrics | head -n 20 || true"

say "4) Покажи systemd-юнит/таймер (cat), чтобы понять зависимости"
for u in wz-api-healthalert.service wz-api-healthalert.timer; do
  run "echo '--- unit: ${u} ---'"
  run "systemctl cat ${u} || true"
done

say "5) Быстрая проверка окружения/переменных healthalert (если есть env-файл)"
# Популярные места: /etc/default, /etc/sysconfig, .env рядом со скриптом
for f in \
  /etc/wz-api-healthalert.env \
  /etc/default/wz-api-healthalert \
  /etc/sysconfig/wz-api-healthalert \
  "${HOME}/.env.wzbot" \
  "/etc/wz/wz-api-healthalert.env"
do
  [ -f "$f" ] && { run "echo '--- env: ${f} ---'"; run "sed -n '1,120p' $f"; }
done

say "6) SSH брутфорс — верхушка айсберга (последние 100 строк)"
run "journalctl -u sshd -n 100 --no-pager || true"

say "7) Резюме и next steps (подсказывает по фактам)"
echo "
[SUMMARY HINTS]
- Если 'ss -lntp' не показывает :3100 и /ready даёт ошибку — Loki не запущен/не слушает: чинить/запускать или править promtail на внешний Loki.
- Если 'systemctl cat wz-api-healthalert.service' показывает Wants=/After= на Loki/promtail — добавить правильные зависимости (After=loki.service) или Reties/BindsTo.
- Если healthalert дерётся за переменные окружения — проверить env-файлы и ExecStart.
- Таймер останется отключён, пока не поправим зависимые компоненты.
" | tee -a "$REPORT"

say "Готово. Отчёт: $REPORT"
