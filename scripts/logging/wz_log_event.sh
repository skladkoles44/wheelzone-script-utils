#!/data/data/com.termux/files/usr/bin/bash
set -eo pipefail
shopt -s failglob nocasematch

# Конфигурация для HyperOS
export TMPDIR="$HOME/.cache/wz_logs"
mkdir -p "$TMPDIR" && chmod 700 "$TMPDIR"

# Настройки OOM Killer
oom_score_adj() {
    echo -100 > /proc/$$/oom_score_adj 2>/dev/null || true
}

# Основные параметры
readonly LOG_DIR="$HOME/.wz_logs"
readonly LOGFILE="$LOG_DIR/permalog.ndjson"
mkdir -p "$LOG_DIR" && chmod 700 "$LOG_DIR"

# Защита от параллельного выполнения
LOCKFILE="$TMPDIR/wz_log_event.lock"
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

# Валидация входных данных
TYPE="${1:-event}"
MSG="${2:-No message}"
SEVERITY="${3:-info}"

# Санитайзинг
TYPE=$(termux-sanitize "$TYPE" 2>/dev/null || printf '%s' "$TYPE" | tr -cd '[:alnum:]-_')
SEVERITY=$(printf '%s' "$SEVERITY" | tr '[:upper:]' '[:lower:]')

# Валидация уровня логирования
case "$SEVERITY" in
    debug|info|warning|error|critical) ;;
    *) SEVERITY="info" ;;
esac

# Экранирование JSON с fallback
MSG_ESCAPED=$(jq -aRs . <<<"$MSG" 2>/dev/null || 
    printf '%s' "$MSG" | sed -e 's/"/\\"/g' -e 's/\\/\\\\/g')

# Атомарная запись лога
TS=$(date --iso-8601=seconds)
{
    echo "{\"ts\":\"$TS\",\"type\":\"$TYPE\",\"message\":\"$MSG_ESCAPED\",\"severity\":\"$SEVERITY\"}"
} >> "$LOGFILE"

# Отправка в Loki с проверкой OOM
if [[ -x ~/wheelzone-script-utils/scripts/logging/wz_loki_push.sh ]]; then
    oom_score_adj
    bash ~/wheelzone-script-utils/scripts/logging/wz_loki_push.sh "$TYPE" "$MSG" "$SEVERITY" &
    disown
fi

# Очистка
flock -u 9
exit 0
