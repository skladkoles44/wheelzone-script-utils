#!/bin/bash
# WheelZone AI Rule Interface v3.1 (OpenRouter + AutoModel + YAML)

WZ_DIR="$HOME/wz-knowledge"
RULES_DIR="$WZ_DIR/rules"
REGISTRY="$WZ_DIR/registry.yaml"
CACHE_DIR="$HOME/.cache/wz_ai"
LOG_FILE="$CACHE_DIR/ai_rule.log"
DEFAULT_TOKEN="pk-anon"
OPENROUTER_URL="https://openrouter.ai/api/v1/chat/completions"
AI_MODEL=""
MANUAL_MODEL=""
MODE=""

init_env() {
    mkdir -p "$RULES_DIR" "$CACHE_DIR" || return 1
    [ -f "$REGISTRY" ] || echo "rules: []" > "$REGISTRY"
    touch "$LOG_FILE" || return 1
    for cmd in curl python3 git uuidgen; do
        command -v "$cmd" >/dev/null || pkg install -y "$cmd" >/dev/null 2>&1
    done
    python3 -c "import yaml" 2>/dev/null || pip install --quiet pyyaml >/dev/null
}

gen_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1
}

auto_select_model() {
    if [ -n "$MANUAL_MODEL" ]; then
        AI_MODEL="$MANUAL_MODEL"
    elif [ "$MODE" = "rule" ]; then
        AI_MODEL="anthropic/claude-3-sonnet"
    elif [ "$MODE" = "dry" ]; then
        AI_MODEL="mistralai/mistral-7b-instruct"
    else
        AI_MODEL="cohere/command-r-plus"
    fi
}

ai_request() {
    local prompt="$1"
    local cache_file="$CACHE_DIR/$(echo -n "$prompt$AI_MODEL" | md5sum | awk '{print $1}').txt"

    if [ -f "$cache_file" ] && [ $(date +%s -r "$cache_file") -gt $(date -d '-5 days' +%s) ]; then
        cat "$cache_file"; return 0
    fi

    local response=$(curl -sS "$OPENROUTER_URL" \
      -H "Authorization: Bearer $DEFAULT_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "model": "'"$AI_MODEL"'",
        "messages": [{"role": "user", "content": "'"${prompt}"'"}],
        "temperature": 0.2,
        "max_tokens": 300
      }')

    local output=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'].strip())" 2>/dev/null)

    [ -n "$output" ] && echo "$output" > "$cache_file"
    echo "$output"
}

create_rule() {
    local input="$1"
    local uuid=$(gen_uuid)
    local date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local file="$RULES_DIR/rule_${uuid}.md"
    local prompt="Сформулируй строгое и лаконичное техническое правило на основе: '$input'. Ответь только текстом правила."

    local result=$(ai_request "$prompt")
    [ -z "$result" ] && echo "AI ошибка или пустой ответ" && return 1

    cat > "$file" <<EOF2
# $(echo "$input" | sed 's/`/\\`/g')
UUID: $uuid
Created: $date

Правило: $(echo "$result" | sed 's/`/\\`/g')
EOF2

    python3 - "$REGISTRY" "$uuid" "$file" "$input" "$date" <<'PYTHON'
import yaml, sys, os, tempfile
regfile, uid, fpath, title, dt = sys.argv[1:6]
with open(regfile) as f:
    data = yaml.safe_load(f) or {"rules": []}
if any(r.get("uuid") == uid for r in data["rules"]):
    sys.exit(1)
data["rules"].append({"uuid": uid, "file": os.path.relpath(fpath, os.path.dirname(regfile)), "title": title, "created_at": dt, "status": "active"})
with tempfile.NamedTemporaryFile("w", delete=False) as tmp:
    yaml.dump(data, tmp, allow_unicode=True, sort_keys=False)
os.replace(tmp.name, regfile)
PYTHON

    (cd "$WZ_DIR" && git add "$file" "$REGISTRY" && \
     git commit -m "auto: rule $uuid" --quiet && \
     git pull --rebase --quiet && \
     git push origin main --quiet) || echo "⚠️ Git ошибка"

    echo "✅ $uuid"
    echo "Файл: $file"
}

print_help() {
    echo "Использование:"
    echo "  $0 rule \"Текст правила\""
    echo "  $0 --model MODEL rule \"Текст\""
    echo "  $0 --model MODEL --dry-run \"Текст\""
    echo "  $0 log"
    echo "  $0 help"
}

main() {
    init_env || { echo "❌ init error"; exit 1; }

    while [[ "$1" =~ ^-- ]]; do
        case "$1" in
            --model) shift; MANUAL_MODEL="$1"; shift ;;
            --dry-run) MODE="dry"; shift ;;
            --help|help) print_help; exit 0 ;;
            *) echo "Неизвестный параметр $1"; exit 1 ;;
        esac
    done

    case "$1" in
        rule) MODE="rule"; shift; auto_select_model; create_rule "$*";;
        log) tail -n40 "$LOG_FILE";;
        *) print_help;;
    esac
}
main "$@"
