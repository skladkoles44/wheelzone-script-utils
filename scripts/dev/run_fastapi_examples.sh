#!/bin/bash
# 🚀 FastAPI Test Runner (Server: Sapphire Holmium)
set -euo pipefail

LOG="/tmp/fastapi_test.log"
> "$LOG"

echo "🔄 Активация окружения..." | tee -a "$LOG"
source ~/venvs/fastapi/bin/activate || {
  echo "❌ Не найден venv fastapi" | tee -a "$LOG"
  exit 1
}

APPS=(
  "/root/fastapi-src/fastapi/docs_src/settings/app01/main.py"
  "/root/fastapi-src/fastapi/docs_src/settings/app02/main.py"
  "/root/fastapi-src/fastapi/docs_src/settings/app03/main.py"
  "/root/fastapi-src/fastapi/docs_src/bigger_applications/app/main.py"
)

RESULTS=()

for path in "${APPS[@]}"; do
  MOD=$(echo "$path" | sed 's|/root/||;s|\.py$||;s|/|.|g')
  echo -e "\n🔹 Тест: $MOD" | tee -a "$LOG"

  pkill -f "uvicorn $MOD" 2>/dev/null || true
  uvicorn "$MOD":app --host 127.0.0.1 --port 8000 --reload >> "$LOG" 2>&1 &
  PID=$!
  sleep 3

  RESP=$(curl -s --max-time 2 http://127.0.0.1:8000 || echo "⚠️ Нет ответа")
  echo -e "Ответ: $RESP\n" | tee -a "$LOG"
  RESULTS+=("🔸 $MOD → $RESP")

  kill $PID 2>/dev/null || true
  sleep 1
done

echo -e "\n📋 Итог:\n$(printf '%s\n' "${RESULTS[@]}")" | tee -a "$LOG"
cat "$LOG" > /tmp/fastapi_final_report.txt
