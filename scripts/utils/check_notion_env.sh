#!/data/data/com.termux/files/usr/bin/python3
#!/data/data/com.termux/files/usr/bin/bash
# Проверка доступности базы данных Notion по .env.wzbot

ENV_FILE="$HOME/.env.wzbot"
NOTION_VERSION="2022-06-28"

log() {
	echo "[$(date +%F' '%T)] $1"
}

err() {
	echo "❌ $1" >&2
	exit 1
}

[[ ! -f "$ENV_FILE" ]] && err "Файл $ENV_FILE не найден"

# Загрузка переменных
export $(grep -E '^(NOTION_API_TOKEN|NOTION_LOG_DB_ID)=' "$ENV_FILE" | xargs)

[[ -z "$NOTION_API_TOKEN" ]] && err "NOTION_API_TOKEN не установлен"
[[ -z "$NOTION_LOG_DB_ID" ]] && err "NOTION_LOG_DB_ID не установлен"

# Удалим дефисы для совместимости
DB_ID_CLEAN="${NOTION_LOG_DB_ID//-/}"

log "Проверка доступа к базе Notion ($DB_ID_CLEAN)..."

RESPONSE=$(curl -s -X GET "https://api.notion.com/v1/databases/$DB_ID_CLEAN" \
	-H "Authorization: Bearer $NOTION_API_TOKEN" \
	-H "Notion-Version: $NOTION_VERSION")

if echo "$RESPONSE" | grep -q '"object": "database"'; then
	log "✅ Доступ к базе подтверждён"
	exit 0
else
	echo "$RESPONSE" | jq .
	err "⛔ Не удалось получить доступ к базе. Проверь .env.wzbot и настройки доступа (Share with integration)."
fi
