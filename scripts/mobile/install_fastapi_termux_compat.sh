#!/data/data/com.termux/files/usr/bin/bash
# WZ Install FastAPI (Termux-Compatible) v2.1

set -eo pipefail
echo "[WZ] Installing compatible FastAPI stack for Termux + Python 3.12..."

# 1. Удаляем сломанные версии (если были)
pip uninstall -y fastapi pydantic pydantic-core uvicorn || true

# 2. Устанавливаем стабильные версии
pip install "pydantic==1.10.9" "fastapi==0.95.2" "uvicorn[standard]==0.22.0"

# 3. Проверка
python3 -c 'from fastapi import FastAPI; print("[✓] FastAPI installed OK")'
