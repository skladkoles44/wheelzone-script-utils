#!/data/data/com.termux/files/usr/bin/bash
# WheelZone AI Rule Hybrid Interface (v3.3 — WBP Hybrid Edition, OpenRouter only, Android-safe)

set -euo pipefail

WZ_DIR="$HOME/wz-knowledge"
RULES_DIR="$WZ_DIR/rules"
REGISTRY="$WZ_DIR/registry.yaml"
CACHE_DIR="$HOME/wz-tmp/wz_ai_cache"
LOG_FILE="$HOME/wz-tmp/wz_ai_rule.log"
OPENROUTER_TOKEN="${OPENROUTER_TOKEN:-pk-anon}"

init_env() {
    mkdir -p "$RULES_DIR" "$CACHE_DIR"
    [[ -f "$REGISTRY" ]] || echo "rules: []" > "$REGISTRY"
    touch "$LOG_FILE"

    for cmd in python3 curl git uuidgen; do
        command -v "$cmd" >/dev/null || pkg install -y "$cmd" >/dev/null 2>&1
    done

    python3 -c "import yaml" 2>/dev/null || pip install --quiet pyyaml >/dev/null 2>&1
}

gen_uuid() {
    uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1 ||
    python3 -c "import uuid; print(str(uuid.uuid4()).split('-')[0])"
}

auto_select_model() {
    local mode="$1"
    local text="$2"
    local len="${#text}"

    if [[ -n "${MANUAL_MODEL:-}" ]]; then
        AI_MODEL="$MANUAL_MODEL"
    else
        case "$mode" in
            rule) AI_MODEL=$([[ $len -gt 500 ]] && echo "anthropic/claude-3-opus" || echo "anthropic/claude-3-sonnet") ;;
            dry) AI_MODEL="mistralai/mistral-7b-instruct" ;;
            *) AI_MODEL="cohere/command-r-plus" ;;
        esac
    fi
}

ai_request() {
    local prompt="$1"
    local cache_hash
    cache_hash=$(echo -n "$prompt$AI_MODEL" | md5sum | awk '{print $1}')
    local cache_file="$CACHE_DIR/${cache_hash}.txt"

    if [[ -f "$cache_file" ]] && [[ $(stat -c %Y "$cache_file") -gt $(date -d '-7 days' +%s) ]]; then
        cat "$cache_file"
        return
    fi

    local response
    response=$(curl -s https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $OPENROUTER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$AI_MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}], \"max_tokens\": 300}" 2>>"$LOG_FILE")

    local content
    content=$(echo "$response" | python3 -c "import sys, json; j = json.load(sys.stdin); print(j['choices'][0]['message']['content'].strip())" 2>>"$LOG_FILE") || {
        echo "AI request failed" >> "$LOG_FILE"
        return 1
    }

    echo "$content" | tee "$cache_file"
}

create_rule() {
    local text="$1"
    local uuid
    uuid=$(gen_uuid)
    local date
    date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local file="$RULES_DIR/rule_${uuid}.md"

    auto_select_model rule "$text"
    local rule_text
    rule_text=$(ai_request "Сформулируй строгое и лаконичное техническое правило на основе: '$text'. Ответь только текстом правила.") || return 1

    printf "# %s\nUUID: %s\nCreated: %s\n\nПравило: %s\n" "${text//\`/\\\`}" "$uuid" "$date" "${rule_text//\`/\\\`}" > "$file"

    python3 -c "
import sys, yaml, tempfile, os
reg, uid, title, created = sys.argv[1:]
with open(reg) as f:
    data = yaml.safe_load(f) or {'rules': []}
if not any(r.get('uuid') == uid for r in data['rules']):
    data['rules'].append({'uuid': uid, 'file': f'rules/rule_{uid}.md', 'title': title, 'created_at': created, 'status': 'active'})
    with tempfile.NamedTemporaryFile('w', delete=False) as tmp:
        yaml.dump(data, tmp, allow_unicode=True, sort_keys=False)
    os.replace(tmp.name, reg)
" "$REGISTRY" "$uuid" "$text" "$date"

    (cd "$WZ_DIR" && git rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
        git add "$file" "$REGISTRY" &&
        git commit -m "auto: rule $uuid" --quiet &&
        git pull --rebase --quiet &&
        git push origin main --quiet) || echo "Git error" >> "$LOG_FILE"

    echo "✅ $uuid"
    echo "Файл: $file"
}

main() {
    init_env || { echo "Ошибка инициализации"; exit 1; }

    while [[ "${1:-}" == --* ]]; do
        case "$1" in
            --model) MANUAL_MODEL="$2"; shift 2 ;;
            *) echo "Неизвестный флаг: $1" >&2; exit 1 ;;
        esac
    done

    case "${1:-}" in
        rule|--create) shift; [[ $# -eq 0 ]] && { echo "Usage: $0 rule \"text\""; exit 1; }; create_rule "$*" ;;
        --dry-run) shift; [[ $# -eq 0 ]] && { echo "Usage: $0 --dry-run \"text\""; exit 1; }; auto_select_model dry "$*"; ai_request "$*" ;;
        log) tail -n40 "$LOG_FILE" 2>/dev/null || echo "Лог не найден" ;;
        help|--help|-h)
            cat <<EOF2
Использование:
  $0 rule "Текст"                  — создать правило
  $0 --model MODEL rule "Текст"    — использовать заданную модель
  $0 --dry-run "Текст"             — тест без сохранения
  $0 log                           — просмотреть лог
EOF2
            ;;
        *) echo "Неизвестная команда: $1"; exit 1 ;;
    esac
}

main "$@"
