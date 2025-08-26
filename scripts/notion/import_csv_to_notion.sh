# uuid: 2025-08-26T13:19:31+03:00-3073135403
# title: import_csv_to_notion.sh
# component: .
# updated_at: 2025-08-26T13:19:31+03:00

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/bin/bash
set -e

CSV_DIR=~/wzbuffer/notion_csv_templates
HELPER=~/wheelzone-script-utils/scripts/notion/helpers/import_csv_to_notion.py
ENV_FILE=~/.env.notion

if [ ! -f "$HELPER" ]; then
  echo "❌ Не найден Python-скрипт: $HELPER"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Не найден .env.notion"
  exit 2
fi

echo "📤 Импорт CSV в Notion..."

for csv in "$CSV_DIR"/*.csv; do
  echo "→ $csv"
  python3 "$HELPER" "$csv" --env "$ENV_FILE"
done

echo "✅ Импорт завершён"
