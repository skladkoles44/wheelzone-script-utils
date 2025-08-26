#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:30+03:00-1608482039
# title: install_rclone_yadisk.sh
# component: .
# updated_at: 2025-08-26T13:19:30+03:00

#!/data/data/com.termux/files/usr/bin/bash
# Установка rclone
pkg install rclone -y

# Копирование конфигурации
mkdir -p ~/.config/rclone
cp ~/wheelzone-script-utils/configs/rclone.conf ~/.config/rclone/rclone.conf

# Создание точки монтирования
mkdir -p ~/mnt/yadisk

# Добавление alias
echo "alias mount_yadisk='rclone mount yadisk: ~/mnt/yadisk --vfs-cache-mode writes'" >>~/.bashrc
source ~/.bashrc

# Уведомление
echo "[✓] Rclone для Yandex Disk установлен. Используй: mount_yadisk"
