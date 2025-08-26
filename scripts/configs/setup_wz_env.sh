#!/bin/bash
# uuid: 2025-08-26T13:19:25+03:00-72812658
# title: setup_wz_env.sh
# component: .
# updated_at: 2025-08-26T13:19:25+03:00

# WheelZone: установка и активация основного окружения wz_env

# 1. Создание окружения, если не существует
if [ ! -d "$HOME/wz_env" ]; then
  echo "🧠 Создаю окружение ~/wz_env"
  python3 -m venv ~/wz_env
fi

# 2. Активация
source ~/wz_env/bin/activate

# 3. Установка необходимых пакетов
pip install --upgrade pip
pip install streamlit sqlite-utils

# 4. Скрипт активации
cat > ~/.venv_activate.sh <<'EOF'
#!/bin/bash
if [ -d "$HOME/wz_env" ]; then
  source "$HOME/wz_env/bin/activate"
  echo "✅ Активировано окружение ~/wz_env"
else
  echo "⚠️ Окружение ~/wz_env не найдено"
fi
EOF
chmod +x ~/.venv_activate.sh

# 5. Добавление в .bashrc
grep -qxF 'source ~/.venv_activate.sh' ~/.bashrc || echo 'source ~/.venv_activate.sh' >> ~/.bashrc

echo "✅ setup_wz_env завершён"
