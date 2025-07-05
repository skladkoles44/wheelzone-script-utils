#!/bin/bash
# WheelZone Doctor — диагностический скрипт для среды WZ

echo "🩺 Запуск диагностики среды WheelZone..."

STATUS_OK=0

# === Проверка rclone.conf ===
echo "🔍 Проверка rclone.conf..."
"$HOME/wheelzone-script-utils/scripts/utils/check_configs.sh"
if [ $? -ne 0 ]; then
  echo "⚠️  Проблема с rclone.conf. Исправь и повтори."
  STATUS_OK=1
else
  echo "✅ rclone.conf в порядке."
fi

# === Проверка точки монтирования ===
echo "📁 Проверка точки ~/mnt/yadisk..."
if [ -d "$HOME/mnt/yadisk" ]; then
  echo "✅ Каталог есть."
else
  echo "⚠️  Нет директории ~/mnt/yadisk. Будет создана при установке."
fi

# === Проверка наличия alias ===
echo "🔍 Проверка alias mount_yadisk..."
if grep -q 'mount_yadisk' "$HOME/.bashrc"; then
  echo "✅ alias mount_yadisk найден."
else
  echo "⚠️  alias mount_yadisk не найден. Установщик его добавит."
fi

# === Итог ===
if [ "$STATUS_OK" -eq 0 ]; then
  echo "✅ Диагностика завершена. Среда готова."
else
  echo "❌ Обнаружены проблемы. Проверь вывод выше."
fi
