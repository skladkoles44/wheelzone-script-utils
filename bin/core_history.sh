#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:04+03:00-2134506272
# title: core_history.sh
# component: .
# updated_at: 2025-08-26T13:19:04+03:00

# WheelZone CLI — core_history.sh

CSV="$HOME/wz-wiki/logs/core_history.csv"

if [[ ! -f "$CSV" ]]; then
  echo "❌ Файл истории не найден: $CSV"
  exit 1
fi

echo "📜 История ядра WheelZone:"
column -s, -t < "$CSV"
