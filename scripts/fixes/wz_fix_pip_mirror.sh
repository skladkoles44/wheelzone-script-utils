#!/bin/bash
# uuid: 2025-08-26T13:19:26+03:00-966415746
# title: wz_fix_pip_mirror.sh
# component: .
# updated_at: 2025-08-26T13:19:26+03:00

# wz_fix_pip_mirror.sh — Автоматическая подмена pip источника и пересборка infra-core

set -euo pipefail
cd ~/wheelzone-infra-nodes

echo "📄 Генерация pip.conf с быстрым зеркалом PyPI (Tuna Tsinghua)..."
cat > pip.conf <<'PIPCONF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
timeout = 30
PIPCONF

echo "🔍 Проверка наличия COPY pip.conf в Dockerfile..."
DOCKERFILE=services/infra-core/Dockerfile
if ! grep -q 'COPY pip.conf /etc/pip.conf' "$DOCKERFILE"; then
  echo "➕ Добавляем COPY pip.conf в Dockerfile..."
  sed -i '1 a COPY pip.conf /etc/pip.conf' "$DOCKERFILE"
else
  echo "✅ COPY pip.conf уже присутствует."
fi

echo "🧹 Удаляем старый контейнер и образ..."
docker rm -f wz_infra_core 2>/dev/null || true
docker rmi wheelzone-infra-nodes-infra-core 2>/dev/null || true

echo "♻️ Пересборка infra-core..."
docker compose -f docker-compose.micro.yml build --no-cache infra-core

echo "🚀 Запуск infra-core..."
docker compose -f docker-compose.micro.yml up -d infra-core

echo "✅ Готово. Проверка состояния..."
docker ps --filter name=wz_infra_core
