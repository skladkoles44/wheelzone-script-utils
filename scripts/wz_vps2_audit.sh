#!/usr/bin/env bash
# WheelZone VPS2 Audit v1.0
# Быстрый аудит последних событий: SSH, sudo, ошибки сервисов

set -euo pipefail

say() { printf "\n=== %s ===\n" "$*"; }

say "📌 Последние входы по SSH (24ч)"
sudo journalctl -u sshd --since "24 hours ago" --no-pager || true

say "📌 Последние sudo-команды (20 строк)"
sudo grep "COMMAND" /var/log/auth.log | tail -n 20 || echo "Нет записей"

say "📌 Ошибки сервисов (последняя загрузка)"
sudo journalctl -p 3 -xb --no-pager || true

say "📌 Общая активность (24ч, 100 строк)"
sudo journalctl --since "24 hours ago" --no-pager | tail -n 100

say "📌 Статус auditd"
systemctl status auditd 2>/dev/null || echo "auditd не установлен"
