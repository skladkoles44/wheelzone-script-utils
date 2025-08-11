#!/usr/bin/env bash
set -euo pipefail

# -------- CONFIG --------
FILES=(
  "$HOME/wz-wiki/docs/index_uuid.md"
  "$HOME/wz-wiki/registry/uuid_orchestrator.yaml"
)
REMOTE_HOST="root@79.174.85.106"
REMOTE_PORT="2222"
RUN_REMOTE_VALIDATOR=1   # 0 — не гонять валидатор на сервере

# (опц) указать эндпоинт оркестратора, если есть:
# export ORCH_LEASE_URL="https://orch.internal/api/lease"
# export ORCH_AUTH="Bearer <token>"

# -------- UUID GENERATOR (многоступенчатый) --------
gen_uuid() {
  # 1) если есть wz_uuid — берём из него
  if command -v wz_uuid >/dev/null 2>&1; then
    # ожидается, что wz_uuid lease печатает UUID одной строкой
    local u
    u="$(wz_uuid lease --kind doc --quiet 2>/dev/null || true)"
    [[ "$u" =~ ^[0-9a-fA-F-]{36}$ ]] && { echo "$u"; return; }
  fi
  # 2) если задан ORCH_LEASE_URL — пробуем curl
  if [[ -n "${ORCH_LEASE_URL:-}" ]] && command -v curl >/dev/null 2>&1; then
    local resp
    resp="$(curl -sf -X POST "$ORCH_LEASE_URL" \
      -H "Content-Type: application/json" \
      ${ORCH_AUTH:+-H "Authorization: $ORCH_AUTH"} \
      -d '{"kind":"doc","trace_id":"'$(date -u +%s%N)'"}' || true)"
    # ищем UUID в ответе
    local u
    u="$(printf '%s' "$resp" | grep -Eo '[0-9a-fA-F-]{36}' | head -n1 || true)"
    [[ "$u" =~ ^[0-9a-fA-F-]{36}$ ]] && { echo "$u"; return; }
  fi
  # 3) fallback — локально uuid4 (временно, чтобы не стопорить работу)
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import uuid; print(str(uuid.uuid4()))
PY
    return
  fi
  echo "ERROR: no UUID source available" >&2
  return 1
}

# -------- helper: update or prepend fractal header --------
# Поддерживаем два стиля:
#   MD:  HTML-комментарий в самом верху <!-- ... -->
#   YAML: хэштеги # ключ: значение
update_header() {
  local file="$1" uuid="$2" md5="$3"

  # определим тип по расширению
  local ext="${file##*.}"

  if [[ "$ext" == "md" ]]; then
    # MD: пытаемся заменить внутри первых 80 строк; если нет — добавим блок в начало
    if grep -m1 -n 'fractal_uuid:' "$file" >/dev/null 2>&1; then
      # заменить строки ключей (внутри HTML-коммента тоже сработает)
      sed -i -E "1,80 s|(fractal_uuid:\s*).*|***REMOVED***${uuid}|" "$file"
      sed -i -E "1,120 s|(content_hash:\s*).*|***REMOVED***${md5}|" "$file"
      sed -i -E "1,80 s|(artifact_path:\s*).*|***REMOVED***docs/index_uuid.md|" "$file"
    else
      # prepend header
      tmp="$(mktemp)"; cat > "$tmp" <<HDR
<!--
fractal_uuid: ${uuid}
issued_at(UTC): 0000-00-00T00:00:00Z
issued_by(device_id): <device_id>
trace_id:
artifact_kind: doc
artifact_path: docs/index_uuid.md
content_hash: ${md5}
-->
HDR
      cat "$tmp" "$file" > "${file}.new" && mv "${file}.new" "$file"
      rm -f "$tmp"
    fi
  else
    # YAML/прочее: комментами с # (первый блок файла)
    if grep -m1 -n '^#\s*fractal_uuid:' "$file" >/dev/null 2>&1; then
      sed -i -E "1,80 s|^#\s*fractal_uuid:\s*.*|# fractal_uuid: ${uuid}|" "$file"
      sed -i -E "1,120 s|^#\s*content_hash:\s*.*|# content_hash: ${md5}|" "$file"
      sed -i -E "1,80 s|^#\s*artifact_path:\s*.*|# artifact_path: registry/uuid_orchestrator.yaml|" "$file"
    else
      tmp="$(mktemp)"; cat > "$tmp" <<HDR
# === FRACTAL HEADER ===
# fractal_uuid: ${uuid}
# issued_at(UTC): 0000-00-00T00:00:00Z
# issued_by(device_id): <device_id>
# trace_id:
# artifact_kind: registry
# artifact_path: registry/uuid_orchestrator.yaml
# content_hash: ${md5}
# === /FRACTAL HEADER ===
HDR
      cat "$tmp" "$file" > "${file}.new" && mv "${file}.new" "$file"
      rm -f "$tmp"
    fi
  fi
}

# -------- main --------
UUID="$(gen_uuid)"
echo "UUID: $UUID"

changed=0
for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "⚠️  Пропуск: $f (нет файла)"
    continue
  fi
  # md5 текущего содержимого (до подстановки!)
  MD5="$(md5sum "$f" | awk '{print $1}')"
  update_header "$f" "$UUID" "$MD5"
  changed=1
  echo "✅ Обновлён header: $f"
done

# Если ничего не меняли — выходим
[[ "$changed" -eq 0 ]] && { echo "ℹ️  Нет целей для обновления"; exit 0; }

# Коммит и пуш
(
  cd "$HOME/wz-wiki"
  git add docs/index_uuid.md registry/uuid_orchestrator.yaml || true
  git commit -m "fractal: set uuid=$UUID and md5 headers" || true
  git push || true
)

# Прогон валидатора локально, если есть
if [[ -x "$HOME/wz-wiki/.ci/check_uuid_index.py" ]]; then
  WZ_CI_JSON_LOG=1 "$HOME/wz-wiki/.ci/check_uuid_index.py" \
    --check-all "$HOME/wz-wiki/docs/index_uuid.md" \
    --policy    "$HOME/wz-wiki/registry/uuid_orchestrator.yaml" || true
fi

# Синк и серверный валидатор
if [[ "$RUN_REMOTE_VALIDATOR" -eq 1 ]]; then
  ssh -p "$REMOTE_PORT" "$REMOTE_HOST" '
    set -e; cd ~/wz-wiki && git pull --ff-only || true
    if [[ -x ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py ]]; then
      WZ_CI_JSON_LOG=1 ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py \
        --check-all ~/wz-wiki/docs/index_uuid.md \
        --policy    ~/wz-wiki/registry/uuid_orchestrator.yaml || true
    fi
  '
fi
