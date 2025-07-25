#!/data/data/com.termux/files/usr/bin/bash
# WZ Loki E2E Test v1.1
set -euo pipefail
IFS=$'\n\t'

LOKI_HOST="79.174.85.106:3100"
test_msg="🧪 Быстрый тест лога"
test_job="test"
test_file="quick.log"
timestamp=$(date +%s)
json_out="$HOME/.wz_logs/loki_e2e_${timestamp}.json"

# Проверка готовности Loki
echo "🧪 Проверка Loki доступности на $LOKI_HOST..."
if curl -s "http://$LOKI_HOST/ready" | grep -q "ready"; then
  echo "✅ Loki готов"
else
  echo "❌ Loki НЕ готов"
  exit 1
fi

# Отправка тестового лога
echo "$test_msg" | logger --tag "$test_job" --stderr

# Подождать, чтобы лог попал в индекс
sleep 3

# Поиск по метке
curl -sG "http://$LOKI_HOST/loki/api/v1/query" \
  --data-urlencode "query={job=\"$test_job\"}" \
  | tee "$json_out" | jq '.data.result' | grep -q "$test_msg"

if [[ $? -eq 0 ]]; then
  echo "✅ Лог успешно найден в Loki"
else
  echo "❌ Не найден лог в Loki"
  echo "💾 Лог сохранён: $json_out"
  ~/bin/wz_notify.sh --msg "❌ E2E Тест Loki не прошёл"
  exit 1
fi

~/bin/wz_notify.sh --msg "✅ E2E Тест Loki пройден успешно"
