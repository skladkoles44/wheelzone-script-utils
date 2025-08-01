#!/data/data/com.termux/files/usr/bin/bash
# ChatEnd CI Runner — v1.1.0 (UUID Core Integrated)
set -eo pipefail

UUID_JSON=$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py --both)
UUID=$(echo "$UUID_JSON" | jq -r '.uuid')
SESSION_ID=$(echo "$UUID_JSON" | jq -r '.session_id')

echo "[CI] UUID: $UUID"
echo "[CI] SESSION_ID: $SESSION_ID"

export SESSION_ID="$SESSION_ID"

# Валидация UUID
if ! echo "$UUID" | grep -Eq '^uuid-[0-9]{14}-[a-f0-9]{6}$'; then
  echo "[CI][ERROR] UUID формат некорректен: $UUID"
  echo "{\"error\": \"Invalid UUID format\", \"uuid\": \"$UUID\"}" > ~/wzbuffer/uuid_error_$(date +%s).json
  exit 1
fi

# Вызов основного chatend-скрипта
~/wheelzone-script-utils/scripts/wz_chatend.sh --ci

# Логгируем в Notion
~/wheelzone-script-utils/scripts/notion/wz_notify_log_uuid.py \
  --uuid "$UUID" \
  --session_id "$SESSION_ID" \
  --source "wzdrone_chatend.sh" \
  --status "validated"
