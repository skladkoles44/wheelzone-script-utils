#!/bin/bash
# v1.2.1 — обновлённые маркеры для wz_generate_diagram и register_notion_tools

LOCK_FILE="${TMPDIR:-/tmp}/wheelzone_patch.lock"
LOG_PATH="$HOME/wheelzone-script-utils/logs/patch_all_log_injection.log"
exec 9>"$LOCK_FILE" || exit 1

if ! flock -n 9; then
    echo "$(date +%F\ %T)  Не удалось получить блокировку после 3 попыток" >>"$LOG_PATH"
    exit 1
fi

log_msg() {
    echo "$(date +%F\ %T)  $*" >>"$LOG_PATH"
}

insert_log_after_marker() {
    local file="$1"
    local marker="$2"
    local log_line="$3"
    if grep -qE "$marker" "$file"; then
        sed -i "/$marker/a $log_line" "$file"
        log_msg "✅ [$file] Вставлен лог после: $marker"
    else
        log_msg "Маркер не найден: '$marker' в $file"
    fi
}

# Вставка в wz_generate_diagram.sh — маркер уже есть
insert_log_after_marker "$HOME/wheelzone-script-utils/scripts/utils/wz_generate_diagram.sh" \
    'event":"done","script":"wz_generate_diagram' \
    'echo "{\"level\":\"INFO\",\"ts\":\"$(date +%Y-%m-%dT%H:%M:%S)\",\"event\":\"final_log\",\"script\":\"wz_generate_diagram\"}" >>"$LOG_FILE"'

# Вставка в register_notion_tools.sh — дописываем в конец
REGISTER_SCRIPT="$HOME/wheelzone-script-utils/scripts/notion/register_notion_tools.sh"
if ! grep -q 'event":"done","script":"register_notion_tools' "$REGISTER_SCRIPT"; then
    echo '' >>"$REGISTER_SCRIPT"
    echo 'echo "{\"level\":\"INFO\",\"ts\":\"$(date +%Y-%m-%dT%H:%M:%S)\",\"event\":\"done\",\"script\":\"register_notion_tools\"}" >>"$LOG_FILE"' >>"$REGISTER_SCRIPT"
    log_msg "✅ [$REGISTER_SCRIPT] Вставлен финальный лог"
else
    log_msg "Пропущено: лог уже есть в $REGISTER_SCRIPT"
fi

log_msg "🏁 Патч завершён"
