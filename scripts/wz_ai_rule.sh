#!/bin/bash
# WheelZone AI Rule Hybrid Interface (v2.3 — компактный)

WZ_DIR="$HOME/wz-knowledge"
RULES_DIR="$WZ_DIR/rules"
REGISTRY="$WZ_DIR/registry.yaml"
AI_KEY_FILE="$HOME/.wz_api_key"
AI_MODEL="gpt-4o"
CACHE_DIR="/tmp/wz_ai_cache"
LOG_FILE="/tmp/wz_ai_rule.log"

init_env() {
    mkdir -p "$RULES_DIR" "$CACHE_DIR" || return 1
    [ -f "$REGISTRY" ] || echo "rules: []" > "$REGISTRY" || return 1
    touch "$LOG_FILE" || return 1
    
    for cmd in python3 git uuidgen jq; do
        command -v "$cmd" >/dev/null || {
            case "$cmd" in
                python3) pkg="python";;
                uuidgen) pkg="util-linux";;
                *) pkg="$cmd";;
            esac
            pkg install -y "$pkg" >/dev/null 2>&1 || return 1
        }
    done
    
    python3 -c "import yaml, requests" 2>/dev/null || 
        pip install --quiet --upgrade pyyaml requests >/dev/null 2>&1
}

get_api_key() {
    [ -n "$AI_API_KEY" ] && return
    
    if [ -f "$AI_KEY_FILE" ]; then
        AI_API_KEY=$(head -n1 "$AI_KEY_FILE" | tr -d '\n\r')
    else
        while true; do
            echo -n "Введите ваш OpenAI API ключ: "
            read -s AI_API_KEY; echo
            [[ "$AI_API_KEY" =~ ^sk-[a-zA-Z0-9]{48}$ ]] && {
                echo "$AI_API_KEY" > "$AI_KEY_FILE"
                chmod 600 "$AI_KEY_FILE"
                break
            }
            echo "Неверный формат ключа (ожидается sk-... с 51 символом)"
            unset AI_API_KEY
        done
    fi
}

gen_uuid() {
    command -v uuidgen >/dev/null && uuidgen | tr '[:upper:]' '[:lower:]' | cut -d'-' -f1 ||
    python3 -c "import uuid; print(str(uuid.uuid4()).split('-')[0])" 2>/dev/null ||
    echo "r$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 7)"
}

ai_request() {
    local prompt="$1"
    local cache_file="$CACHE_DIR/$(echo -n "$prompt" | md5sum | awk '{print $1}').txt"
    
    [ -f "$cache_file" ] && [ $(date +%s -r "$cache_file") -gt $(date -d '-7 days' +%s) ] && {
        cat "$cache_file"
        return 0
    }
    
    local ai_text=$(python3 - "$AI_API_KEY" "$AI_MODEL" "$prompt" 2>>"$LOG_FILE" <<'PYTHON'
import requests, sys
try:
    r = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {sys.argv[1]}"},
        json={
            "model": sys.argv[2],
            "messages": [{"role": "user", "content": sys.argv[3]}],
            "temperature": 0.2,
            "max_tokens": 250
        },
        timeout=15
    )
    if r.status_code != 200:
        print(f"HTTP Error {r.status_code}: {r.text}", file=sys.stderr)
        sys.exit(1)
    print(r.json()['choices'][0]['message']['content'].strip())
except Exception as e:
    print(f"Request failed: {str(e)}", file=sys.stderr)
    sys.exit(1)
PYTHON
    )
    
    [ $? -eq 0 ] && [ -n "$ai_text" ] && {
        mkdir -p "$CACHE_DIR"
        echo "$ai_text" > "$cache_file"
        echo "$ai_text"
        return 0
    }
    
    echo "Ошибка AI-запроса" >> "$LOG_FILE"
    return 1
}

create_rule() {
    [ -z "$1" ] && { echo "Ошибка: пустой текст" >> "$LOG_FILE"; return 1; }
    
    local text="$1"
    local uuid=$(gen_uuid)
    local date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local file="$RULES_DIR/rule_${uuid}.md"
    local prompt="Сформулируй строгое и лаконичное техническое правило на основе: '$text'. Ответь только текстом правила."
    
    local rule_text=$(ai_request "$prompt") || { echo "Ошибка генерации правила" >> "$LOG_FILE"; return 1; }
    [ -z "$rule_text" ] && { echo "Пустой ответ от AI" >> "$LOG_FILE"; return 1; }
    
    cat > "$file" <<EOF
# $(echo "$text" | sed 's/`/\\`/g')
UUID: $uuid
Created: $date

Правило: $(echo "$rule_text" | sed 's/`/\\`/g')
