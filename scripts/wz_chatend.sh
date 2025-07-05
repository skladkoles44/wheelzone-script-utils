#!/usr/bin/env bash
# wz_chatend.sh v2.4 — генератор отчётов завершённых чатов (Markdown+YAML)
# Требования: bash, sha256sum, uuidgen, python3

set -euo pipefail

INSIGHTS_FILE="${INSIGHTS_FILE:-$HOME/wzbuffer/tmp_insights.txt}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/wz-knowledge/WZChatEnds}"
SCRIPT_VERSION="2.4"

generate_sha256() {
  sha256sum "$1" | awk '{print $1}'
}

generate_uuid_from_file() {
  python3 -c "import uuid; print(str(uuid.uuid5(uuid.NAMESPACE_URL, open('$1').read())))"
}

chatend_metadata_block() {
  local filename="$1"
  local uuid="$2"
  local slug="$3"
  local sha256_hash="$4"
  local date_now
  date_now=$(date +"%Y-%m-%d")

  echo "---"
  echo "uuid: $uuid"
  echo "slug: $slug"
  echo "filename: \"${filename}\""
  echo "date: \"$date_now\""
  echo "sha256: \"$sha256_hash\""
  echo "generator: wz_chatend.sh v$SCRIPT_VERSION"
  echo "format: markdown+yaml"
  echo "---"
}

main() {
  if [[ ! -f "$INSIGHTS_FILE" ]]; then
    echo "Файл $INSIGHTS_FILE не найден." >&2
    exit 1
  fi

  mkdir -p "$OUTPUT_DIR"

  local date_str slug filename uuid hash
  date_str=$(date +"%Y-%m-%d")
  slug=$(grep -m1 '^SLUG:' "$INSIGHTS_FILE" | cut -d':' -f2- | xargs | tr ' ' '_' | tr -cd '[:alnum:]_-')
  slug=${slug:-no-slug}
  filename="chat_${date_str}_${slug}.md"
  filepath="$OUTPUT_DIR/$filename"

  cp "$INSIGHTS_FILE" "$filepath"

  hash=$(generate_sha256 "$filepath")
  uuid=$(generate_uuid_from_file "$filepath")

  {
    echo ""
    chatend_metadata_block "$filename" "$uuid" "$slug" "$hash"
  } >> "$filepath"

  echo "[+] ChatEnd отчёт сохранён: $filepath"
}

main "$@"

# === Автофиксация восстановления rclone.conf ===
if [[ -f "$HOME/.config/rclone/rclone.conf" ]]; then
  echo "🧩 Обнаружен rclone.conf — создаю chatend-запись..."
  OUT="$HOME/wz-wiki/WZChatEnds/chat_$(date +%Y%m%d)_auto_rclone_restore.yaml"
  REMOTE=$(grep -o '^\[[^]]*\]' ~/.config/rclone/rclone.conf | tr -d '[]')
  EXPIRY=$(grep -o '"expiry":"[^"]*"' ~/.config/rclone/rclone.conf | cut -d':' -f2 | tr -d '"')

  cat > "$OUT" <<EOR
chatend:
  id: rclone_restore_$(date +%s)
  title: Автофиксация восстановления rclone.conf ($REMOTE)
  type: chatend
  remote: $REMOTE
  token_expiry: $EXPIRY
  status: completed
  created_at: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  context: Termux / Android / WheelZone
EOR
fi
