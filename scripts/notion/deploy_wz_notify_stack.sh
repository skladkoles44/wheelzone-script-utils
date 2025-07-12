#!/data/data/com.termux/files/usr/bin/python3
#!/data/data/com.termux/files/usr/bin/bash
# ───────────────────────────────────────────────
# 🚀 PROD-оптимизированный деплой (Termux/HyperOS)
# ───────────────────────────────────────────────

# Atomic config (readonly)
declare -r LOG_DIR="$HOME/wzbuffer/logs"
declare -r LOCK_FILE="$LOG_DIR/.deploy.lock"
declare -r SCRIPT_PATH="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh"

# Инициализация с блокировкой
mkdir -p "$LOG_DIR" || exit 1
exec 9>"$LOCK_FILE" || exit 1
flock -n 9 || {
	echo "[ERROR] Процесс уже выполняется"
	exit 1
}

# Потоковое логирование
log() {
	printf '{"ts":"%s","msg":"%s"}\n' "$(date +%s)" "$1" >>"$LOG_DIR/deploy.json" --
}

# Основная функция
deploy() {
	log "START"

	# 1. Валидация скрипта
	[ -x "$SCRIPT_PATH" ] || {
		log "ERROR: Скрипт неисполняем"
		return 1
	}

	# 2. Запуск с замером времени
	local start=$EPOCHSECONDS
	if "$SCRIPT_PATH"; then
		log "SUCCESS: Скрипт выполнен ($((EPOCHSECONDS - start))s)"
	else
		log "ERROR: Ошибка выполнения (код $?)"
		return 1
	fi
}

# Вызов с обработкой ошибок
if deploy; then
	log "COMPLETE"
else
	log "FAILED"
	exit 1
fi
