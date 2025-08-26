#!/bin/bash
# uuid: 2025-08-26T13:19:26+03:00-1682516917
# title: check_docker_cleanup.sh
# component: .
# updated_at: 2025-08-26T13:19:26+03:00

# === WZ Docker Cleanup Check (Server Edition) ===

set -euo pipefail
LOG="/tmp/docker_cleanup_check.log"
> "$LOG"

echo "🟢 Активные контейнеры:" | tee -a "$LOG"
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" | tee -a "$LOG"

echo -e "\n🔴 Остановленные контейнеры:" | tee -a "$LOG"
docker ps -a -f status=exited --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" | tee -a "$LOG"

echo -e "\n📦 Неиспользуемые образы:" | tee -a "$LOG"
docker images -f dangling=true --format "table {{.ID}}\t{{.Repository}}\t{{.Size}}" | tee -a "$LOG"

echo -e "\n📁 Объёмы данных:" | tee -a "$LOG"
docker system df | tee -a "$LOG"

echo -e "\n📁 Объёмы docker volume:" | tee -a "$LOG"
docker volume ls | tee -a "$LOG"

echo -e "\n✅ Готово. Полный лог в $LOG"
