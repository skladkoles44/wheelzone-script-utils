#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-2577794612
# title: vz_run_with_task.sh
# component: .
# updated_at: 2025-08-26T13:20:17+03:00


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
