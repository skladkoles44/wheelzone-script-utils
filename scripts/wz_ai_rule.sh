#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:44+03:00-1597954787
# title: wz_ai_rule.sh
# component: .
# updated_at: 2025-08-26T13:19:44+03:00

# WheelZone AI Rule Interface v3.6 (Fractal Optimized)

set -eo pipefail
shopt -s nocasematch

# === Фрактальные примитивы ===
die() { echo "[ERR] $1" >&2; exit 1; }
warn() { echo "[WARN] $1" >&2; }
log() { echo "[+] $1"; }

# === Константы ===
init_consts() {
    WZ_DIR="$HOME/wz-wiki"
    RULES_DIR="$WZ_DIR/rules"
    REGISTRY="$WZ_DIR/registry/registry.yaml"
    CACHE_DIR="$HOME/.cache/wz_ai"
    LOG_FILE="$CACHE_DIR/ai_rule.log"
}

# === Инициализация ===
init_dirs() {
    mkdir -p "$RULES_DIR" "$CACHE_DIR" || die "Не удалось создать директории"
}

# === Проверки ===
check_deps() {
    command -v python3 &>/dev/null || die "Python3 не установлен"
}

# === Help ===
show_help() {
    echo "Фрактальная система управления правилами:"
    echo "Usage: $0 --create <slug> <content>"
    echo "       $0 --help"
    exit 0
}

# === Создание правила ===
create_rule() {
    local slug="$1"
    local content="$2"
    
    slug=$(clean_slug "$slug") || die "Недопустимый slug"
    local rule_id=$(gen_uuid)
    local rule_file="$RULES_DIR/${slug}.md"
    
    check_overwrite "$rule_file" || return 1
    
    create_rule_file "$rule_file" "$slug" "$content" || die "Ошибка записи правила"
    update_registry "$slug" "$rule_id" || die "Ошибка обновления реестра"
    
    log "Правило создано: $rule_file"
    log_event "$rule_id" "cli"
}

# === Вспомогательные фракталы ===
clean_slug() { echo "$1" | tr -cd '[:alnum:]_-'; }
gen_uuid() { bash $HOME/wheelzone-script-utils/scripts/utils/generate_uuid.sh 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +"%s%N-%N"; }

check_overwrite() {
    [[ ! -f "$1" ]] && return 0
    read -rp "[WARN] Файл $1 уже существует. Перезаписать? (y/N) " answer
    [[ "$answer" == "y" ]]
}

create_rule_file() {
    cat > "$1" <<EOR
# Rule: $2

$3
EOR
}


log_event() {
    python3 "$HOME/wheelzone-script-utils/scripts/Loki/wz_notify_log_uuid.py" \
        --type "ai_rule" \
        --node "termux" \
        --source "wz_ai_rule.sh" \
        --title "🚦 Выполнение AI-правила" \
        --message "Правило: $1 | Режим: $2" 2>> "$LOG_FILE" || \
        warn "Логгер недоступен"
}

# === Фрактальный диспетчер ===
main() {
    init_consts
    init_dirs
    check_deps
    
    case "$1" in
        --create) shift; create_rule "$@" ;;
        --help|-h) show_help ;;
        *) die "Неизвестный параметр: $1"
    esac
}

main "$@"
update_registry() {
    python3 -c "
import sys, yaml, os
f = '$REGISTRY'
try:
    os.makedirs(os.path.dirname(f), exist_ok=True)
    if os.path.exists(f):
        with open(f) as fp:
            try:
                data = yaml.safe_load(fp)
                if not isinstance(data, dict):
                    data = {}
            except yaml.YAMLError:
                data = {}
    else:
        data = {}

    rules = data.get('rules', [])
    if not isinstance(rules, list):
        rules = []
    if any(r.get('slug') == '$1' for r in rules if isinstance(r, dict)):
        print('[WARN] Правило с таким slug уже существует', file=sys.stderr)
        sys.exit(1)

    rules.append({'id': '$2', 'slug': '$1'})
    data['rules'] = rules
    with open(f, 'w') as out:
        yaml.safe_dump(data, out, allow_unicode=True)
except Exception as e:
    print('[ERR]', str(e), file=sys.stderr)
    sys.exit(1)
" 2>> "$LOG_FILE"
}
