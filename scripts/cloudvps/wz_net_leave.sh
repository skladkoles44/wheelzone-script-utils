#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:24+03:00-1156185228
# title: wz_net_leave.sh
# component: .
# updated_at: 2025-08-26T13:19:24+03:00

#!/data/data/com.termux/files/usr/bin/bash

# WZ — Отключение от приватной сети с автоуправлением сервером

TOKEN="$1"     # API токен CloudVPS
VPC_ID="$2"    # ID приватной сети
REGLET_ID="$3" # ID сервера (реглета)

API="https://api.cloudvps.reg.ru/v1"
HEADERS=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

# === Проверка статуса сервера ===
echo "[I] Проверка статуса сервера $REGLET_ID"
STATUS=$(curl -s -X GET "${HEADERS[@]}" "$API/reglets/$REGLET_ID" | jq -r '.reglet.status')

if [[ "$STATUS" != "active" ]]; then
	echo "[I] Сервер выключен. Включаем..."
	curl -s -X POST "${HEADERS[@]}" -d '{"type": "start"}' "$API/reglets/$REGLET_ID/actions" >/dev/null
	echo "[I] Ожидание загрузки сервера..."
	sleep 20
else
	echo "[I] Сервер уже включён."
fi

# === Отключение от приватной сети ===
echo "[I] Выполняется отключение сервера от приватной сети $VPC_ID..."
curl -s -X DELETE "${HEADERS[@]}" "$API/vpcs/$VPC_ID/members/$REGLET_ID" >/dev/null
echo "[✔] Сервер успешно отключён от приватной сети."

# === Выключение сервера ===
echo "[I] Отключаем сервер $REGLET_ID, чтобы избежать тарификации..."
curl -s -X POST "${HEADERS[@]}" -d '{"type": "stop"}' "$API/reglets/$REGLET_ID/actions" >/dev/null
echo "[✔] Сервер остановлен."
