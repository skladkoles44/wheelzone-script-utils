# === Notion Logger Stub (v2.0) ===
NOTION_LOG_DIR="$HOME/.wz_notion_logs"
NOTION_LOG_INDEX="$NOTION_LOG_DIR/index.txt"

init_notion_logger() {
    mkdir -p "$NOTION_LOG_DIR"
    [[ ! -f "$NOTION_LOG_INDEX" ]] && touch "$NOTION_LOG_INDEX"
}

log_notion_request() {
    local event_type="${1:-chatend}"
    local payload="$2"
    local status="${3:-stubbed}"
    local request_id=$(uuidgen | tr -d '-')
    local timestamp=$(date -Iseconds)
    local date_prefix=$(date +%Y-%m-%d)
    local log_file="$NOTION_LOG_DIR/${date_prefix}_${request_id}.json"

    cat > "$log_file" <<JSON
{
  "meta": {
    "system": "wz_chatend.sh",
    "version": "2.3.2",
    "environment": "test"
  },
  "request": {
    "id": "$request_id",
    "type": "$event_type",
    "timestamp": "$timestamp",
    "status": "$status",
    "payload": $payload
  }
}
JSON

    echo "$timestamp $request_id $event_type $status" >> "$NOTION_LOG_INDEX"
    sleep 0.1
    cat <<JSON
{
  "stub_response": {
    "id": "$request_id",
    "status": "logged",
    "database": "notion_stub",
    "timestamp": "$timestamp"
  }
}
JSON
}

process_chatend() {
    init_notion_logger
    local payload=$(jq -n --arg file "$OUTPUT_FILE" --arg slug "$SLUG" '{action: "create", file: $file, slug: $slug}')
    echo "📦 Отправка в Notion (заглушка)..."
    log_notion_request "chatend_create" "$payload" "stubbed" >/dev/null
}
