#!/bin/bash

CONFIG_FILE="$HOME/wheelzone-script-utils/configs/rclone.conf"

echo "🔍 Проверка: rclone.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Файл $CONFIG_FILE не найден!"
  exit 1
fi

if ! grep -q '\[yadisk\]' "$CONFIG_FILE"; then
  echo "❌ Не найден remote [yadisk]"
  exit 2
fi

if ! grep -q 'pass = ' "$CONFIG_FILE"; then
  echo "❌ Не найден параметр pass"
  exit 3
fi

echo "✅ rclone.conf валиден."
exit 0
