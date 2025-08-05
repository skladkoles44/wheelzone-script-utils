: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/data/data/com.termux/files/usr/bin/bash
#!/data/data/com.termux/files/usr/bin/bash
# PROD-оптимизированный скрипт синхронизации ChatEnd с Notion
# Версия: 2.0.1

set -eo pipefail

# Конфигурация (immutable)
declare -rA CONFIG=(
	[YAML_PATH]="$HOME/wz-wiki/WZChatEnds/end_blocks.yaml"
	[JSON_PATH]="$HOME/wz-wiki/WZChatEnds/data.json"
	[GENERATOR]="$HOME/wheelzone-script-utils/scripts/notion/generate_notion_log_json.sh"
	[LOGGER]="$HOME/wheelzone-script-utils/scripts/notion/notion_log_entry.py"
	[LOCK_FILE]="$HOME/.cache/wz_locks/sync_chatend_to_notion.lock"
)

# Структурированное логирование
log() {
	local level="$1"
	local message="$2"
	printf '{"time":"%s","level":"%s","message":"%s" --}\n' \
		"$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		"$level" \
		"$(echo "$message" | sed 's/"/\\"/g')" >&2
}

# Безопасная блокировка
acquire_lock() {
	exec 9>"${CONFIG[LOCK_FILE]}" || {
		log "ERROR" "Не удалось открыть lock-файл"

# Валидация зависимостей
validate_dependencies() {
	local deps=("flock" "jq" "python3")
	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			log "ERROR" "Не найдена зависимость: $dep"
			return 2
		fi
	done
}

# Основной процесс
main() {
	acquire_lock || return 1
	validate_dependencies || return 2

	[[ -f "${CONFIG[YAML_PATH]}" ]] || {
		log "ERROR" "YAML файл не найден"
		return 3
	}

	log "INFO" "Запуск генератора JSON"
	if ! bash "${CONFIG[GENERATOR]}"; then
		log "ERROR" "Ошибка генерации JSON"
		return 4
	fi

	log "INFO" "Отправка в Notion"
	if ! python3 "${CONFIG[LOGGER]}" "${CONFIG[JSON_PATH]}"; then
		log "ERROR" "Ошибка отправки в Notion"
		return 5
	fi

	log "INFO" "Синхронизация завершена успешно"
}

main "$@"
EOF &&
	chmod 750 ~/wheelzone-script-utils/scripts/notion/sync_chatend_to_notion.sh

# === Генерация лог-файла отчёта ===
echo "🧠 Генерация лог-файла отчёта..."
bash "$HOME/wheelzone-script-utils/scripts/notion/generate_notion_log_json.sh" --from-markdown || {
  echo "❌ Ошибка при генерации отчёта. Проверь формат markdown-файла."
  exit 1
}
    flock -n 9 || {
        pid=$(cat "${CONFIG[LOCK_FILE]}" 2>/dev/null)
        pid=${pid:-unknown}
        echo "{\"time\":\"$(date -Iseconds)\",\"level\":\"ERROR\",\"message\":\"Процесс уже выполняется (PID: $pid)\"}"
        return 1
    }

    echo "$$" > "${CONFIG[LOCK_FILE]}"
    trap 'rm -f "${CONFIG[LOCK_FILE]}"; trap - EXIT' EXIT
