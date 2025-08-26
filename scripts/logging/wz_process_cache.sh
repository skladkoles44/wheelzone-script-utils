#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:29+03:00-1715858119
# title: wz_process_cache.sh
# component: .
# updated_at: 2025-08-26T13:19:29+03:00

# wz_process_cache v3.1 — Quantum Notification Cache Processor (Fractal AI Compliant)

set -eo pipefail
IFS=$'\n\t'

### 🔧 Конфигурация
declare -r CACHE_DIR="$HOME/.cache/wz_notify"
declare -r KEY_FILE="$HOME/.config/wz_notify.key"
declare -r NOTIFY_SCRIPT="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh"
declare -r LOG_FILE="$HOME/.local/var/log/wz_notify_cache.log"
declare -r LOCK_FILE="$CACHE_DIR/wz_cache.lock"
declare -ri MAX_RETRIES=3
declare -ri RETRY_DELAY=2

### 📂 Инициализация
init() {
    mkdir -p "${CACHE_DIR}" "${LOG_FILE%/*}" || {
        echo "FATAL: Cannot create directories" >&2
        exit 1
    }
    touch "${LOG_FILE}" 2>/dev/null || {
        echo "FATAL: Cannot write to log file" >&2
        exit 1
    }
}

log() {
    printf "[%(%F %T)T] %s: %s\n" -1 "${1^^}" "${2}" >> "${LOG_FILE}"
    [[ "$1" == "error" ]] && echo "ERROR: ${2}" >&2
}

verify() {
    local -a deps=("openssl" "jq")
    for dep in "${deps[@]}"; do
        command -v "${dep}" >/dev/null || {
            log error "Missing dependency: ${dep}"
            exit 1
        }
    done

    [[ -f "${KEY_FILE}" ]] || {
        log error "Missing key file: ${KEY_FILE}"
        exit 1
    }

    [[ -x "${NOTIFY_SCRIPT}" ]] || {
        log error "Notify script not executable: ${NOTIFY_SCRIPT}"
        exit 1
    }
}

### 🔄 Обработка файлов
process_file() {
    local -r enc_file="$1"
    local tmp_file="${enc_file}.tmp.$$"
    local status=1

    log info "Processing: ${enc_file##*/}"

    if openssl enc -aes-256-cbc -d -md sha512 -a -pass file:"${KEY_FILE}" \
       -in "${enc_file}" -out "${tmp_file}" 2>>"${LOG_FILE}" && 
       jq empty "${tmp_file}" 2>>"${LOG_FILE}"; then

        for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "🔔 CALL: $NOTIFY_SCRIPT" >> "${LOG_FILE}"
    echo "📤 PAYLOAD:
$(cat "$tmp_file")" >> "${LOG_FILE}"
    echo "🔔 CALL: $NOTIFY_SCRIPT" >> "${LOG_FILE}"
    echo "📤 PAYLOAD:
$(cat "$tmp_file")" >> "${LOG_FILE}"
            echo "📤 Launching notify: $NOTIFY_SCRIPT < $tmp_file" >> "${LOG_FILE}"
            echo "🧪 DEBUG: $NOTIFY_SCRIPT will be launched with tmp_file=$tmp_file" >> "${LOG_FILE}"
            if "${NOTIFY_SCRIPT}" --stdin < "${tmp_file}" >>"${LOG_FILE}" 2>&1; then
                rm -f "${enc_file}" "${tmp_file}"
                log info "Delivered: ${enc_file##*/}"
                status=0
                break
            fi
            sleep "${RETRY_DELAY}"
        done
    fi

    [[ "${status}" -ne 0 ]] && {
        log error "Failed to process: ${enc_file##*/}"
        rm -f "${tmp_file}"
    }

    return "${status}"
}

### ♻️ Главный цикл
main() {
    init
    verify

    (
        flock -n 200 || {
            log info "Processor already running"
            exit 0
        }

        shopt -s nullglob
        local -a files=("${CACHE_DIR}"/*.enc)
        local file

        if [[ "${#files[@]}" -eq 0 ]]; then
            log info "No files to process"
            exit 0
        fi

        log info "Starting processing of ${#files[@]} files"
        
        for file in "${files[@]}"; do
            process_file "${file}" &
        done

        wait
        log info "Processing complete"
    ) 200>"${LOCK_FILE}"
}

main "$@"
