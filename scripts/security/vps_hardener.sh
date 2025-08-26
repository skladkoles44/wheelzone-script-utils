#!/bin/bash
# uuid: 2025-08-26T13:19:33+03:00-3664615717
# title: vps_hardener.sh
# component: .
# updated_at: 2025-08-26T13:19:33+03:00

# vps_hardener.sh — Автоматическая настройка безопасности VPS

set -euo pipefail
echo "🚧 [Hardener] Начинаем настройку безопасности..."

# 1. Обновление
sudo apt update && sudo apt upgrade -y

# 2. Fail2Ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 3. UFW
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw --force enable

# 4. SSH настройка
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl reload sshd

echo "✅ Безопасность VPS усилена."
