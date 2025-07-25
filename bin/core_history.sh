#!/data/data/com.termux/files/usr/bin/bash
# WheelZone CLI — core_history.sh

CSV="$HOME/wz-wiki/logs/core_history.csv"

if [[ ! -f "$CSV" ]]; then
  echo "❌ Файл истории не найден: $CSV"
  exit 1
fi

echo "📜 История ядра WheelZone:"
column -s, -t < "$CSV"
