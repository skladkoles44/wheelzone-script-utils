#!/bin/bash
# uuid: 2025-08-26T13:19:53+03:00-3642422702
# title: check_idle.sh
# component: .
# updated_at: 2025-08-26T13:19:53+03:00

LOG=~/wz_idle.log
echo "[`date`] Проверка активности..." >> $LOG

# Проверка активных SSH-сессий
SSH_SESSIONS=$(who | grep -cE 'pts|tty')

# Проверка загрузки CPU за последние 1 мин (если меньше 0.1 — считаем бездействием)
CPU_LOAD=$(uptime | awk -F 'load average:' '{ print $2 }' | cut -d',' -f1 | awk '{print $1}')
CPU_LOAD_INT=$(echo "$CPU_LOAD < 0.1" | bc)

# Проверка активных Docker контейнеров
DOCKER_RUNNING=$(docker ps -q | wc -l)

if [ "$SSH_SESSIONS" -eq 0 ] && [ "$DOCKER_RUNNING" -eq 0 ] && [ "$CPU_LOAD_INT" -eq 1 ]; then
    echo "[`date`] Состояние: ПУСТОЙ. Инициирую остановку VPS..." >> $LOG
    curl -s -X POST "https://api.reg.ru/api/regru2/vps/service/stop"       -d "username=info@skladkoles44.ru"       -d "password=wzAPI_2025!"       -d "service_id=4769594" >> $LOG
else
    echo "[`date`] Состояние: Активен (SSH: $SSH_SESSIONS, Docker: $DOCKER_RUNNING, CPU: $CPU_LOAD)" >> $LOG
fi
