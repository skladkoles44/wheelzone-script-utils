#!/data/data/com.termux/files/usr/bin/bash
# WheelZone ChatEnd Generator v1.4.3 (Android 15 HyperOS Optimized)

set -eo pipefail
shopt -s nullglob failglob nocasematch

# === Конфигурация ===
readonly DEFAULT_OUTPUT_DIR="${HOME}/wz-wiki/WZChatEnds"
readonly TIMESTAMP="$(date +%Y%m%d-%H%M%S-%3N)"
readonly UUID="$(cat /proc/sys/kernel/random/uuid || uuidgen || python3 -c 'import uuid; print(uuid.uuid4())')"
readonly SLUG="$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
readonly FILENAME="${TIMESTAMP}-${UUID//-/}-${SLUG}.md"
readonly OUTPUT_PATH="${DEFAULT_OUTPUT_DIR}/${FILENAME}"
readonly BUFFER_DIR="$HOME/wzbuffer"
readonly END_BLOCKS_FILE="${BUFFER_DIR}/end_blocks.txt"
readonly INSIGHTS_FILE="${BUFFER_DIR}/tmp_insights.txt"

mkdir -p "$DEFAULT_OUTPUT_DIR" "$BUFFER_DIR"

# === Обработка вложенных FRACTAL файлов ===
process_fractal_lines() {
  local input_file="$1"
  local normalized_path line match nested_input

  if [[ ! -f "$input_file" ]]; then
    echo "[ERROR] Файл не существует: $input_file" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ FRACTAL:.* ]]; then
      match="${BASH_REMATCH[0]}"
      nested_input="${match#FRACTAL:}"
      nested_input="${nested_input#:}"
      nested_input="${nested_input/#\~/$HOME}"
      nested_input="${nested_input//[\'\"]/}"

      if command -v realpath >/dev/null 2>&1; then
        normalized_path=$(realpath -m "$nested_input" 2>/dev/null) || {
          echo "[ERROR] Не удалось нормализовать путь: $nested_input" >&2
          continue
        }
      else
        normalized_path="$nested_input"
      fi

      if [[ -f "$normalized_path" ]]; then
        echo "[INFO] Обработка вложенного файла: $normalized_path" >&2
        process_fractal_lines "$normalized_path"
      else
        echo "[ERROR] Вложенный файл не существует: $normalized_path" >&2
        continue
      fi
    else
      echo "$line"
    fi
  done < "$input_file"
}

# === Генерация блока end_blocks.yaml ===
generate_end_blocks_yaml() {
  local output_file="$1"
  {
    echo "# blocks extracted from chat — generated $(date -Iseconds)"
    echo "uuid: ${UUID}"
    echo "slug: ${SLUG}"
    echo "timestamp: ${TIMESTAMP}"
    echo "chatend_file: ${FILENAME}"
    echo "blocks:"
    grep -Poz '(?s)(?<=^|[\n\r])```(DONE|TODO|INSIGHT|RULE)\n.*?\n```' "$END_BLOCKS_FILE" |
      awk 'BEGIN{RS="```"; ORS=""} /^(DONE|TODO|INSIGHT|RULE)\n/ {print "- |\n  " $0 "\n"}'
  } > "${BUFFER_DIR}/end_blocks.yaml"
}

# === Основная генерация ===
generate_chatend_file() {
  {
    echo "# ChatEnd Report"
    echo "**UUID:** ${UUID}"
    echo "**Slug:** ${SLUG}"
    echo "**Timestamp:** ${TIMESTAMP}"
    echo
    echo "## Extracted End Blocks"
    cat "$END_BLOCKS_FILE"
    echo
    echo "## Insights"
    cat "$INSIGHTS_FILE" 2>/dev/null || echo "_no insights_"
  } > "$OUTPUT_PATH"
  echo "✅ ChatEnd сохранён: $FILENAME"
}

# === Запуск ===
if [[ "$1" == "--fractal" && -n "$2" ]]; then
  process_fractal_lines "$2"
  exit 0
fi

generate_end_blocks_yaml "$END_BLOCKS_FILE"
generate_chatend_file
