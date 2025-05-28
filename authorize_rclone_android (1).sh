#!/data/data/com.termux/files/usr/bin/bash

CONFIG_DIR="$HOME/.config/rclone"
SECRET_JSON="$CONFIG_DIR/client_secret.json"

echo "[INFO] Используем OAuth авторизацию с Android. Проверка client_secret..."

if [ ! -f "$SECRET_JSON" ]; then
  echo "[ERROR] Не найден $SECRET_JSON"
  echo "Сначала положи туда свой client_secret_*.json"
  exit 1
fi

CLIENT_ID=$(jq -r '.installed.client_id' "$SECRET_JSON")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$SECRET_JSON")

AUTH_CMD="rclone authorize \"drive\" \"{\\\"client_id\\\":\\\"$CLIENT_ID\\\",\\\"client_secret\\\":\\\"$CLIENT_SECRET\\\",\\\"scope\\\":\\\"drive\\\"}\""

echo "$AUTH_CMD" | termux-clipboard-set

echo "[NEXT] Открой новый терминал Termux или эмулятор и вставь из буфера."
echo "[INFO] После авторизации получишь JSON. Вставь его обратно в rclone."
