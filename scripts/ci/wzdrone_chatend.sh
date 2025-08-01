#!/data/data/com.termux/files/usr/bin/bash
# wzdrone_chatend.sh — CI-интеграция генерации ChatEnd (Termux HyperOS совместимость)
set -euo pipefail

# === Настройка окружения ===
CI_NODE="termux-hyperos"
CI_SOURCE="ci/wzdrone_chatend.sh"
CI_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
CI_UUID="$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py --quantum)"
SESSION_ID="${CI_UUID##*-}"

echo "[CI] UUID: $CI_UUID"
echo "[CI] SESSION_ID: $SESSION_ID"

# === Генерация ChatEnd ===
OUT_FILE="$(bash ~/wheelzone-script-utils/scripts/wz_chatend.sh --from-markdown ~/wzbuffer/end_blocks.txt)"
echo "[INFO] Сохранено: $OUT_FILE"

# === Логирование в Notion ===
python3 ~/wheelzone-script-utils/scripts/notion/wz_notify_log_uuid.py \
  --uuid "$CI_UUID" \
  --type "chatend" \
  --node "$CI_NODE" \
  --source "$CI_SOURCE" \
  --timestamp "$CI_TIMESTAMP" \
  --title "✅ ChatEnd успешно сгенерирован" \
  --message "Файл ${OUT_FILE##*/} создан через CI-процедуру на ${CI_NODE}"
