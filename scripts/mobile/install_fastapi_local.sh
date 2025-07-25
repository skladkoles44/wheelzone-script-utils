#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 📦 Константы
WHEEL_DIR="$HOME/wzbuffer/fastapi_wheels"
DOWNLOAD_DIR="/storage/emulated/0/Download"

PYDANTIC_WHL="pydantic-1.10.13-py3-none-any.whl"
FASTAPI_WHL="fastapi-0.110.0-py3-none-any.whl"
STARLETTE_WHL="starlette-0.36.3-py3-none-any.whl"
TYPING_EXT_WHL="typing_extensions-4.8.0-py3-none-any.whl"
ANYIO_WHL="anyio-4.9.0-py3-none-any.whl"

mkdir -p "$WHEEL_DIR"

echo "📦 Копируем .whl из $DOWNLOAD_DIR..."
for WHL in "$PYDANTIC_WHL" "$FASTAPI_WHL" "$STARLETTE_WHL" "$TYPING_EXT_WHL" "$ANYIO_WHL"; do
    cp "$DOWNLOAD_DIR/$WHL" "$WHEEL_DIR/" || {
        echo "❌ Файл $WHL не найден в Download"; exit 1;
    }
done

echo "📁 Содержимое $WHEEL_DIR:"
ls -lh "$WHEEL_DIR"

echo "🚀 Установка FastAPI и зависимостей..."
pip install --force-reinstall --no-index \
  --find-links="$WHEEL_DIR" \
  fastapi==0.110.0 \
  pydantic==1.10.13 \
  starlette==0.36.3 \
  typing-extensions==4.8.0 \
  anyio==4.9.0

echo "✅ Установка завершена!"
