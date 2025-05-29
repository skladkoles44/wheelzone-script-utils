#!/data/data/com.termux/files/usr/bin/bash

# Запуск сервера
echo "🔄 Запускаем сервер..."
curl -s -X POST https://api.cloudvps.reg.ru/v1/reglets/4769594/actions \
  -H "Authorization: Bearer $REG_VZ_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "start"}' | jq

echo "⏳ Ожидаем 60 секунд для загрузки сервиса..."
sleep 60

# Запуск задачи (например, docker run или ssh)
echo "🚀 Выполняем задачу..."
# Пример:
# ssh root@89.111.171.170 'docker ps -a'

# Завершение работы сервера
echo "🔻 Отключаем сервер..."
curl -s -X POST https://api.cloudvps.reg.ru/v1/reglets/4769594/actions \
  -H "Authorization: Bearer $REG_VZ_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "stop"}' | jq

echo "✅ Задача завершена. Сервер остановлен."
