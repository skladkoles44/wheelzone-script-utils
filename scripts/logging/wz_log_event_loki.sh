#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:28+03:00-2044782342
# title: wz_log_event_loki.sh
# component: .
# updated_at: 2025-08-26T13:19:28+03:00

# WZ Loki Logger v1.1 — Optimized Loki Client

set -eo pipefail
IFS=$'\n\t'
trap 'echo "🛑 [wz_log_event_loki] CRASHED | Args: $*" >&2' ERR

declare -r LOKI_URL="${LOKI_URL:-http://127.0.0.1:3100/loki/api/v1/push}"
declare -r TIMEOUT=5
declare -r MAX_RETRIES=2
declare -r HOST="${HOST:-$(hostname -s 2>/dev/null || echo termux)}"
declare -rA DEFAULT_LABELS=(
    [host]="$HOST"
    [app]="wheelzone"
    [env]="termux"
)

main() {
    local severity="${1,,}"
    local message="${2:-No message provided}"
    local timestamp=$(date +%s%N)

    validate_severity "$severity" || severity="info"
    send_to_loki "$severity" "$timestamp" "$message"
}

validate_severity() {
    case "$1" in
        info|warn|error|critical) return 0 ;;
        *) return 1 ;;
    esac
}

generate_payload() {
    local severity="$1"
    local timestamp="$2"
    local message="$3"

    jq -n \
        --arg ts "$timestamp" \
        --arg msg "$message" \
        --arg severity "$severity" \
        --arg host "${DEFAULT_LABELS[host]}" \
        --arg app "${DEFAULT_LABELS[app]}" \
        --arg env "${DEFAULT_LABELS[env]}" \
        '{
            streams: [{
                stream: {
                    severity: $severity,
                    host: $host,
                    app: $app,
                    env: $env
                },
                values: [[$ts, $msg]]
            }]
        }'
}

send_to_loki() {
    local attempt=0
    local payload=$(generate_payload "$@")

    while (( attempt++ < MAX_RETRIES )); do
        if curl -sSf --connect-timeout $TIMEOUT \
                -H "Content-Type: application/json" \
                -d "$payload" \
                "$LOKI_URL" >/dev/null; then
            return 0
        fi
        sleep 1
    done

    echo "⚠️ Failed to send logs after $MAX_RETRIES attempts" >&2
    return 1
}

main "$@"
