#!/bin/bash
# uuid: 2025-08-26T13:20:12+03:00-1547968006
# title: release_gatekeeper.sh
# component: .
# updated_at: 2025-08-26T13:20:12+03:00

# Проверка консистентности перед git/rclone push
echo "[GATEKEEPER] Проверка..."
if grep -q planned file_versions_index.json; then
  echo "ОШИБКА: Есть незавершённые файлы (status: planned). Прекращаю."
  exit 1
fi
echo "[GATEKEEPER] Все проверки пройдены. Продолжайте."
exit 0
