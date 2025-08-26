# uuid: 2025-08-26T13:19:32+03:00-4213965736
# title: wz_import_chatlinks.sh
# component: .
# updated_at: 2025-08-26T13:19:32+03:00

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

: "${WZ_LOG_DIR:=$HOME/.wz_logs}"
mkdir -p "$WZ_LOG_DIR"

#!/data/data/com.termux/files/usr/bin/bash
# WheelZone Import ChatLinks v1.0 (оптимизированная версия)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="$HOME/wzbuffer/notion_csv_templates/chatlink_map.csv"
PY_SCRIPT="$SCRIPT_DIR/import_chat_links.py"
LOG_FILE="$HOME/.wzlogs/import_chatlinks.log"
ENV_FILE="$HOME/.env.notion"

PYTHON_CMD="python3"
if [[ -z ${WZ_PYTHON_CMD_CACHE+x} ]]; then
    if command -v pypy3 >/dev/null 2>&1; then
        PYTHON_CMD="pypy3"
    fi
    export WZ_PYTHON_CMD_CACHE="$PYTHON_CMD"
else
    PYTHON_CMD="$WZ_PYTHON_CMD_CACHE"
fi

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$CSV_FILE")"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    if [[ -t 1 ]]; then
        echo "$msg" | tee -a "$LOG_FILE"
    else
        echo "$msg" >> "$LOG_FILE"
    fi
}

check_file() {
    if [[ ! -f "$1" ]]; then
        log "❌ Файл не найден: $1"
        return 1
    fi
    return 0
}

log_and_exit() {
    local status=$1
    local message=$2
    log "$message"
    $PYTHON_CMD "$SCRIPT_DIR/notion_log_entry.py" \
        --type "script-event" \
        --script "import_chat_links.py" \
        --status "$status" \
        --message "$message"
    exit $(( status == "success" ? 0 : 3 ))
}

main() {
    local required_files=("$CSV_FILE" "$PY_SCRIPT")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        check_file "$file" || missing_files+=("$file")
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log "❌ Отсутствуют файлы: ${missing_files[*]}"
        exit 1
    fi

    log "🚀 Начало импорта: $CSV_FILE"
    if $PYTHON_CMD "$PY_SCRIPT" "$CSV_FILE"; then
        log_and_exit "success" "✅ Импорт успешно завершён"
    else
        log_and_exit "error" "❌ Ошибка при импорте"
    fi
}

main
