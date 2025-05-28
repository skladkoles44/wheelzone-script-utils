#!/data/data/com.termux/files/usr/bin/bash

echo "[CLEAN-RCLONE] Остановка всех процессов rclone..."
pkill -f rclone

echo "[CLEAN-RCLONE] Удаление записей cron, связанных с BackUp..."
crontab -l | grep -v 'BackUp' | crontab -

echo "[CLEAN-RCLONE] Очистка старых alias в .bashrc и .zshrc..."
sed -i '/BackUp/d' ~/.bashrc 2>/dev/null
sed -i '/BackUp/d' ~/.zshrc 2>/dev/null

echo "[CLEAN-RCLONE] Проверка и очистка конфигурации rclone..."
CONFIG=~/.config/rclone/rclone.conf
if [ -f "$CONFIG" ]; then
    sed -i '/BackUp/d' "$CONFIG"
fi

echo "[CLEAN-RCLONE] Очистка завершена. Перезапусти Termux или выполни 'source ~/.bashrc'"