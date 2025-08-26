#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:09+03:00-1309217789
# title: install_shop_db.sh
# component: .
# updated_at: 2025-08-26T13:20:09+03:00


# === Настройки подключения (замени при необходимости) ===
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_USER="root"
SSH_HOST="89.111.171.170"
REMOTE_TMP="/tmp/init_shop_db.sql"
LOCAL_SQL="$HOME/storage/downloads/project_44/Termux/Script/init_shop_db_optimized.sql"

# === Генерация сложного пароля ===
DB_PASSWORD=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)

# === Подстановка пароля в SQL-файл ===
sed "s|\$DB_PASSWORD|$DB_PASSWORD|g" "$LOCAL_SQL" > /tmp/init_temp.sql

# === Копирование на VPS ===
scp -i "$SSH_KEY" /tmp/init_temp.sql "$SSH_USER@$SSH_HOST:$REMOTE_TMP"

# === Выполнение на VPS ===
ssh -i "$SSH_KEY" "$SSH_USER@$SSH_HOST" "mysql -uroot -p'hdDBDjFXBG6UICE9' < $REMOTE_TMP"

# === Удаление временного файла и вывод пароля ===
rm /tmp/init_temp.sql
echo
echo 'Установка завершена.'
echo "Пароль пользователя shop_app: $DB_PASSWORD"
