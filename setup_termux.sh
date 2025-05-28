#!/data/data/com.termux/files/usr/bin/bash
# WheelZone: автоматическая настройка Termux-окружения (Android)

echo "[*] Обновление пакетов Termux..."
pkg update -y && pkg upgrade -y

echo "[*] Установка базовых утилит..."
pkg install -y git curl jq openssh tsu htop nano coreutils

echo "[*] Создание .ssh директории (если нет)..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "[*] Установка SSH-ключа WheelZone..."
cat <<EOF > ~/.ssh/id_ed25519
-----BEGIN OPENSSH PRIVATE KEY-----
# <-- вставь приватный ключ вручную после копирования из ПК
# иначе Termux не подключится к серверу без пароля
EOF
chmod 600 ~/.ssh/id_ed25519

cat <<EOF > ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0i+U+X/UetFkfC53DQgAK86AmLHT6hx5Wm0gU1nePK wheelzone-dev
EOF
chmod 644 ~/.ssh/id_ed25519.pub

echo "[*] Настройка alias и автодоступов..."
mkdir -p ~/bin

# SSH alias
echo "alias wzvps='ssh root@89.111.171.170'" >> ~/.bashrc

# Встроенные скрипты управления VPS
cat <<'EOV' > ~/bin/vzstart
curl -s -X POST "https://api.reg.ru/api/regru2/vps/service/start" \
  -d "username=info@skladkoles44.ru" \
  -d "password=wzAPI_2025!" \
  -d "service_id=4769594" | jq .
EOV

cat <<'EOV' > ~/bin/vzstop
curl -s -X POST "https://api.reg.ru/api/regru2/vps/service/stop" \
  -d "username=info@skladkoles44.ru" \
  -d "password=wzAPI_2025!" \
  -d "service_id=4769594" | jq .
EOV

chmod +x ~/bin/vz*

echo "[*] Установка rclone..."
pkg install -y rclone

echo "[*] Завершено. Перезапусти Termux или введи: source ~/.bashrc"
