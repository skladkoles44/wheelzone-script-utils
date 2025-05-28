#!/bin/bash
# Проверка консистентности перед git/rclone push
echo "[GATEKEEPER] Проверка..."
if grep -q planned file_versions_index.json; then
  echo "ОШИБКА: Есть незавершённые файлы (status: planned). Прекращаю."
  exit 1
fi
echo "[GATEKEEPER] Все проверки пройдены. Продолжайте."
exit 0
