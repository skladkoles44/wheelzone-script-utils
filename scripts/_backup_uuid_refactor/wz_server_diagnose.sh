#!/bin/bash
set -eEuo pipefail
trap '_error_handler $?' ERR

# === Константы ===
readonly LOG_DIR="${HOME}/wz_diag"
readonly LOG_FILE="${LOG_DIR}/diag_$(date +%Y%m%d_%H%M%S).log"
readonly MAX_LOG_FILES=10
readonly LOCK_FILE="$PREFIX/tmp/wz_diag.lock"

# === Инициализация ===
mkdir -p "$LOG_DIR"

# === Логирование ===
log() {
    local msg="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

# === Очистка старых логов ===
cleanup_old_logs() {
    find "$LOG_DIR" -name "diag_*.log" -type f | sort -r | tail -n +$((MAX_LOG_FILES+1)) | xargs -r rm -f --
}

# === Лок-файл ===
acquire_lock() {
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log "Другой экземпляр уже работает"; exit 1; }
}

# === Диагностика ===
run_diagnostics() {
    log "=== НАЧАЛО ДИАГНОСТИКИ ==="

    log "СИСТЕМА:"
    uname -a | tee -a "$LOG_FILE"
    uptime | tee -a "$LOG_FILE"

    log "РЕСУРСЫ:"
    command -v free >/dev/null && free -h | awk '/Mem/ {print "Память: "$3"/"$2}' | tee -a "$LOG_FILE" || log "free не найден"
    command -v df >/dev/null && df -h / | awk 'NR==2 {print "Диск: "$4"/"$2}' | tee -a "$LOG_FILE" || log "df не найден"

    log "СЕТЬ:"
    if command -v ss >/dev/null; then
        ss -tuln | grep LISTEN | tee -a "$LOG_FILE"
    else
        log "ss не найден"
    fi

    log "=== ДИАГНОСТИКА ЗАВЕРШЕНА ==="
}

# === Обработчик ошибок ===
_error_handler() {
    local code=$1
    log "ОШИБКА: код $code"
    exit $code
}

# === main ===
main() {
    acquire_lock
    cleanup_old_logs
    run_diagnostics
}
main "$@"
