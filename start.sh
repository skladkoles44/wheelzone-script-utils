
#!/bin/bash

echo "==> Создание .env из шаблона..."
cp .env.example .env

echo "==> Запуск Docker-контейнеров..."
docker-compose -f infra/docker-compose.yml up --build -d

echo "==> Ожидание запуска базы данных..."
sleep 10

echo "==> Применение миграций..."
docker exec -i skladkoles44-api alembic upgrade head

echo "==> Проект успешно запущен!"
echo "FastAPI:   http://localhost:8000/docs"
echo "Frontend:  http://localhost:5173"
