#!/data/data/com.termux/files/usr/bin/bash
# HYPEROS ULTIMATE CORE v1.4.1-FRACTAL
# License: GNU GPLv3 + Android Exception
# UUID: wzcore-hyperos-1491c

set -Eeo pipefail
trap '__crash_handler $? $LINENO "${BASH_COMMAND}"' ERR TERM INT HUP QUIT

declare -rx ANDROID_API=$(getprop ro.build.version.sdk)
declare -rx TERMUX_PREFIX="/data/data/com.termux/files/usr"
declare -rx SECURE_TMP=$(mktemp -d "$TERMUX_PREFIX/tmp/.core_XXXXXX")
declare -rx LOG_PATH="$HOME/wheelzone-script-utils/logs/hypercore.log"
mkdir -p "$(dirname "$LOG_PATH")"
chmod 700 "$SECURE_TMP"

__validate_env() {
    [[ "$ANDROID_API" -ge 30 ]] || {
        echo "⛔ Need Android 12+ (Detected API $ANDROID_API)" >&2
        exit 1
    }

    [[ "$(id -u)" -ne 2000 ]] || {
        echo "⛔ Running as isolated_app is forbidden" >&2
        exit 1
    }

    [[ -w "$TERMUX_PREFIX" ]] || {
        echo "⛔ Termux prefix not writable" >&2
        exit 1
    }
}

__make_unkillable() {
    local pid=$$
    echo "-1000" > /proc/$pid/oom_score_adj 2>/dev/null
    renice -n 3 -p $pid >/dev/null
    (sleep 3; while true; do nice -n 5 true; sleep 60; done) & disown
}

__crash_handler() {
    local code=$1 line=$2 cmd="$3"
    __secure_log "EMERGENCY: Code $code at $line: $cmd"

    {
        echo "=== CORE DUMP ==="
        date
        printenv
        echo "Line $line: $cmd"
        history 5
    } > "$SECURE_TMP/last_crash.log"

    sync
    termux-notification -t "Core Crash" -c "Line $line: $cmd" --id 911
    exit 1
}

__secure_log() {
    local msg="$(date '+%Y-%m-%d %T') | $$ | $1"
    echo "$msg" >> "$SECURE_TMP/core.log"
    echo "$msg" >> "$LOG_PATH"
    
    [[ "$ANDROID_API" -ge 33 ]] && termux-notification -t "Core Log" -c "$1" --priority high
}

__hyper_io() {
    if grep -q 'mmcblk' /proc/partitions; then
        echo 1024 > /sys/block/mmcblk0/queue/read_ahead_kb
    fi

    sync
    echo 3 > /proc/sys/vm/drop_caches
    ionice -c2 -n3 -p $$ >/dev/null
}

main() {
    __validate_env
    __make_unkillable
    __hyper_io

    {
        termux-wake-lock --name hyperos_core && trap 'termux-wake-unlock' EXIT
    } 2>/dev/null || __secure_log "Wake lock failed"

    __secure_log "System initialized (Fractal Kernel Online)"
}

case "$1" in
    --armor)
        exec -a "[kworker/1:1]" nice -n 10 "$0" --real
        ;;
    --real)
        main "$@"
        ;;
    *)
        setsid "$0" --armor </dev/null >/dev/null 2>&1 &
        ;;
esac
