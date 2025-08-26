#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:40+03:00-2660548084
# title: sync_uuid_status.sh
# component: .
# updated_at: 2025-08-26T13:19:40+03:00

set -euo pipefail

# === CONFIG ===
YAML_FILE="$HOME/wz-wiki/registry/uuid_orchestrator.yaml"
MD_FILE="$HOME/wz-wiki/docs/index_uuid.md"
VALIDATOR="$HOME/wz-wiki/.ci/check_uuid_index.py"
REMOTE="root@79.174.85.106"
PORT="2222"

# === 1. Проверка наличия файлов ===
for f in "$YAML_FILE" "$MD_FILE" "$VALIDATOR"; do
    [[ -f "$f" ]] || { echo "❌ Файл не найден: $f" >&2; exit 1; }
done

# === 2. Получение статуса из YAML ===
STATUS=$(grep -E '^status:' "$YAML_FILE" | awk '{print $2}')
[[ -n "$STATUS" ]] || { echo "❌ Статус пуст" >&2; exit 1; }

# === 3. Обновление статуса в MD ===
sed -i "s/^\(\*\*Статус:\*\*\).*/***REMOVED*** $STATUS/" "$MD_FILE"
echo "✅ Статус синхронизирован: $STATUS"

# === 4. MD5-хэш ===
MD5_HASH=$(md5sum "$MD_FILE" | awk '{print $1}')
echo "📦 MD5: $MD5_HASH"
grep -q '\*\*MD5:\*\*' "$MD_FILE" \
    && sed -i "s/^\(\*\*MD5:\*\*\).*/***REMOVED*** $MD5_HASH/" "$MD_FILE" \
    || echo "**MD5:** $MD5_HASH" >> "$MD_FILE"

# === 5. Проверка валидатором ===
WZ_CI_JSON_LOG=1 "$VALIDATOR" \
  --check-all "$MD_FILE" \
  --policy    "$YAML_FILE"

# === 6. Локальный git push ===
cd "$HOME/wz-wiki"
git add "$MD_FILE" "$YAML_FILE"
git commit -m "🔄 Sync status=$STATUS, md5=$MD5_HASH"
git push

# === 7. Синк на сервер ===
ssh -p "$PORT" "$REMOTE" "
  cd ~/wz-wiki && git pull --ff-only &&
  WZ_CI_JSON_LOG=1 ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py \
    --check-all ~/wz-wiki/docs/index_uuid.md \
    --policy    ~/wz-wiki/registry/uuid_orchestrator.yaml
"

echo "🎯 Синхронизация и проверка завершены"
