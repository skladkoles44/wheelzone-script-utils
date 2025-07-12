#!/bin/bash
set -euo pipefail

# === Конфигурация ===
TOKEN_FILE="$HOME/.wz_api_token"
SERVER_ID=4957608  # Sapphire Holmium (IP: 79.174.85.106)
DELAY_MINUTES=10   # Время работы сервера в минутах

API="https://api.cloudvps.reg.ru/v1"
AUTH="Authorization: Bearer $(cat "$TOKEN_FILE")"

# === Проверка статуса сервера ===
status=$(curl -s -H "$AUTH" "$API/reglets/$SERVER_ID" | grep -Po '"status":\s*"\K[^"]+')

if [[ "$status" == "off" ]]; then
  echo "[INFO] Сервер выключен. Пытаемся включить..."
  curl -s -X POST -H "$AUTH" "$API/reglets/$SERVER_ID/actions/start"
  echo "[WAIT] Ожидание загрузки сервера (60 сек)..."
  sleep 60
else
  echo "[INFO] Сервер уже активен. Пропускаем включение."
fi

# === Работа сервера ===
echo "[RUNNING] Сервер будет активен $DELAY_MINUTES минут..."
sleep "$((DELAY_MINUTES * 60))"

# === Отключение сервера ===
echo "[SHUTDOWN] Завершаем работу. Выключаем сервер..."
curl -s -X POST -H "$AUTH" "$API/reglets/$SERVER_ID/actions/stop"
echo "[DONE] Сервер успешно выключен."
