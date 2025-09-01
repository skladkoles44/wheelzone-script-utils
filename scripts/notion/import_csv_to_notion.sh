# uuid: 2025-08-26T13:19:31+03:00-3073135403
# title: import_csv_to_Loki.sh
# component: .
# updated_at: 2025-08-26T13:19:31+03:00

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/bin/bash
set -e

CSV_DIR=~/wzbuffer/Loki_csv_templates
HELPER=~/wheelzone-script-utils/scripts/Loki/helpers/import_csv_to_Loki.py
ENV_FILE=~/.env.Loki

if [ ! -f "$HELPER" ]; then
  echo "❌ Не найден Python-скрипт: $HELPER"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Не найден .env.Loki"
  exit 2
fi

echo "📤 Импорт CSV в Loki..."

for csv in "$CSV_DIR"/*.csv; do
  echo "→ $csv"
  python3 "$HELPER" "$csv" --env "$ENV_FILE"
done

echo "✅ Импорт завершён"
