#!/usr/bin/env bash
# title: WZ :: UUID→BIGINT Mapper Addon
# version: 1.1.0 (universal)
set -Eeuo pipefail; IFS=$'\n\t'

ENTITY="${1:?entity required: product|variant|price|stock}"
BIGID="${2:?bigint_id required}"

# UUID из канонического моста
UUID="$(bash "$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_bridge.sh" take | head -n1)"
[ -z "$UUID" ] && { echo "[ERR] no uuid"; exit 1; }

# Определяем окружение
if command -v psql >/dev/null 2>&1; then
  # VPS: есть Postgres
  PSQL="psql -v ON_ERROR_STOP=1 -d wz_products"
  $PSQL <<EOSQL
INSERT INTO core.uuid_map(uuid, bigint_id, entity)
VALUES ('${UUID}', ${BIGID}, '${ENTITY}')
ON CONFLICT (uuid) DO NOTHING;
EOSQL
else
  echo "[WZ] No Postgres here, skipping DB insert (Termux mode)."
fi

# Локальный журнал (универсальный)
LOGDIR="$HOME/.wz_logs"; mkdir -p "$LOGDIR"
printf '{"ts":"%s","uuid":"%s","bigint_id":%s,"entity":"%s","action":"map"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$UUID" "$BIGID" "$ENTITY" \
  >> "$LOGDIR/uuid_map.ndjson"

echo "[WZ] mapped $ENTITY: $BIGID -> $UUID"
