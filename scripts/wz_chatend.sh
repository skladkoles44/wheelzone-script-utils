#!/data/data/com.termux/files/usr/bin/bash
# wz_chatend.sh v2.3.2-fractal+notify — ChatEnd Generator + Fractal + Telegram

set -eo pipefail
shopt -s nullglob nocasematch
export LANG="C.UTF-8"

readonly OUTPUT_DIR="${HOME}/wz-wiki/WZChatEnds"
readonly INSIGHT_FILE="${HOME}/wzbuffer/tmp_insights.txt"
readonly FRACTAL_LOG="${HOME}/.wz_logs/fractal_chatend.log"
readonly UUID="$(uuidgen | tr -d '-')"
readonly TIMESTAMP="$(date +%Y-%m-%dT%H-%M-%S)"
# PATCHED_OUT_FILE_FIX
unset OUT_FILE 2>/dev/null || true
OUT_FILE="${OUTPUT_DIR}/${TIMESTAMP}-${UUID}.md"
readonly TG_BOT_TOKEN="${TG_BOT_TOKEN:-}"
readonly TG_CHAT_ID="${TG_CHAT_ID:-}"
readonly FRACTAL_ID="${BASHPID}_$RANDOM"
FRACTAL_DEPTH="${FRACTAL_DEPTH:-0}"

mkdir -p "$OUTPUT_DIR" "$(dirname "$INSIGHT_FILE")" ~/.wz_logs/

send_telegram() {
  [[ -n "$TG_BOT_TOKEN" && -n "$TG_CHAT_ID" ]] || return 0
  local message="$1"
  curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
       -d "chat_id=${TG_CHAT_ID}&text=${message}" &>/dev/null
}

flog() {
  local depth_pad=$(printf "%*s" "$FRACTAL_DEPTH" "")
  local log_msg="[${FRACTAL_ID}] ${depth_pad}↳ $*"
  echo "$log_msg" | tee -a "$FRACTAL_LOG"
  send_telegram "$log_msg"
}

generate_chatend() {
  flog "🌀 Генерация ChatEnd в: $OUT_FILE"
  {
    echo "# 📦 ChatEnd Report — ${TIMESTAMP}"
    echo
    echo "## ✅ DONE"
    grep '^DONE:' "$INSIGHT_FILE" | cut -c6- || echo "_нет_"
    echo
    echo "## 🧩 TODO"
    grep '^TODO:' "$INSIGHT_FILE" | cut -c6- || echo "_нет_"
    echo
    echo "## 💡 INSIGHTS"
    grep '^INSIGHT:' "$INSIGHT_FILE" | cut -c9- || echo "_нет_"
  } > "$OUT_FILE"
  flog "✔️ ChatEnd сохранён: $(basename "$OUT_FILE")"
# === Заглушка логирования события ChatEnd в Notion ===
NOTION_LOGGER_SCRIPT="$HOME/wheelzone-script-utils/scripts/notion/notion_logger_stub.sh"
if [[ -f "$NOTION_LOGGER_SCRIPT" ]]; then
    source "$NOTION_LOGGER_SCRIPT"
    SLUG="$(basename "$OUT_FILE" .md)"
    OUTPUT_FILE="$OUT_FILE"
    process_chatend
else
    echo "⚠️ Notion Logger заглушка не найдена: $NOTION_LOGGER_SCRIPT"
fi
}

process_fractals() {
  local input="$1"
  grep -oE '\[\[FRACTAL:.*\]\]' "$input" | while read -r match; do
    local nested_file="${match:9:-2}"
    if [[ -f "$nested_file" ]]; then
      ((FRACTAL_DEPTH++))
      flog "🔍 Обнаружен вложенный фрактал: $nested_file"
      FRACTAL_DEPTH="$FRACTAL_DEPTH" "$0" --fractal "$nested_file"
      ((FRACTAL_DEPTH--))
    else
      flog "⚠️ Не найден файл: $nested_file"
    fi
  done
}

main() {
  case "$1" in
    --auto)
      generate_chatend
      ;;
    --fractal)
      shift
      flog "🌿 Запуск фрактальной обработки файла: $1"
      OUT_FILE="${OUTPUT_DIR}/fractal-${TIMESTAMP}-${UUID}.md"
      cp "$1" "$OUT_FILE"
      process_fractals "$1"
      ;;
    --tg-test)
      send_telegram "✅ Тест уведомления из wz_chatend.sh: $(date)"
      ;;
    *)
      echo "Использование:"
      echo "  --auto             Генерация ChatEnd из $INSIGHT_FILE"
      echo "  --fractal FILE     Обработка ChatEnd с вложениями [[FRACTAL:...]]"
      echo "  --tg-test          Тест уведомления Telegram"
      ;;
  esac
}

main "$@"

# === Заглушка: Запись ChatEnd события в SQLite-базу на VPS ===
{
    CHATEND_UUID="${FINAL_UUID:-$(uuidgen)}"
    CHATEND_FILE="${OUT_FILE:-unknown.md}"
    CHATEND_TYPE="chatend"
    CHATEND_TIMESTAMP="$(date -Iseconds)"

    echo "📦 Заглушка: Запись в SQLite (пока без соединения)"
    echo "INSERT INTO wz_chatends (uuid, file_name, type, timestamp) VALUES ('$CHATEND_UUID', '$CHATEND_FILE', '$CHATEND_TYPE', '$CHATEND_TIMESTAMP');"
} >> ~/.wz_logs/sqlite_log_placeholder.sql
