#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:34+03:00-4261818746
# title: check_configs.sh
# component: .
# updated_at: 2025-08-26T13:19:34+03:00

#!/data/data/com.termux/files/usr/bin/bash

CONFIG_FILE="$HOME/wheelzone-script-utils/configs/rclone.conf"

echo "🔍 Проверка: rclone.conf"

if [ ! -f "$CONFIG_FILE" ]; then
	echo "❌ Файл $CONFIG_FILE не найден!"
	exit 1
fi

if ! grep -q '\[yadisk\]' "$CONFIG_FILE"; then
	echo "❌ Не найден remote [yadisk]"
	exit 2
fi

if ! grep -q 'pass = ' "$CONFIG_FILE"; then
	echo "❌ Не найден параметр pass"
	exit 3
fi

echo "✅ rclone.conf валиден."
exit 0
