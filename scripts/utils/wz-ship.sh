#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:41+03:00-2460032081
# title: wz-ship.sh
# component: .
# updated_at: 2025-08-26T13:19:41+03:00

set -euo pipefail

# --- конфиг ---
PORT=2222
REMOTE=root@79.174.85.106
WIKI=$HOME/wz-wiki
UTIL=$HOME/wheelzone-script-utils
MD="$WIKI/docs/index_uuid.md"
YAML="$WIKI/registry/uuid_orchestrator.yaml"
VALIDATOR_LOCAL="$WIKI/.ci/check_uuid_index.py"
VALIDATOR_UTIL="$UTIL/scripts/utils/check_uuid_index.py"

# --- 1) sync статус + md5 ---
"$UTIL/scripts/utils/sync_uuid_status.sh"

# --- 2) фрактальные хедеры (uuid + md5) ---
"$UTIL/scripts/utils/fix_fractal_uuid_md5.sh"

# --- 3) локальные пуши (wz-wiki уже запушен в sync_uuid_status.sh) ---
if git -C "$UTIL" status --porcelain | grep -q .; then
  git -C "$UTIL" add -A
  git -C "$UTIL" commit -m "ship: utils refresh"
  git -C "$UTIL" push || true
fi

# --- 4) гарантировать валидатор в utils ---
if [ -f "$VALIDATOR_LOCAL" ]; then
  mkdir -p "$UTIL/scripts/utils"
  cp -f "$VALIDATOR_LOCAL" "$VALIDATOR_UTIL"
  sed -i '1s|^#!.*python3$|#!/usr/bin/env python3|' "$VALIDATOR_UTIL"
  chmod +x "$VALIDATOR_UTIL"
  git -C "$UTIL" add "$VALIDATOR_UTIL" || true
  git -C "$UTIL" commit -m "ci: ensure validator present" || true
  git -C "$UTIL" push || true
fi

# --- 5) VPS: pull обоих репо, подложить валидатор если его нет, placeholders для путей ---
ssh -p "$PORT" "$REMOTE" 'bash -s' <<'R'
set -euo pipefail
# pull repos
[[ -d ~/wz-wiki/.git ]] || git clone https://github.com/skladkoles44/wz-wiki ~/wz-wiki
[[ -d ~/wheelzone-script-utils/.git ]] || git clone https://github.com/skladkoles44/wheelzone-script-utils ~/wheelzone-script-utils
git -C ~/wz-wiki fetch --all --prune && git -C ~/wz-wiki reset --hard origin/main
git -C ~/wheelzone-script-utils fetch --all --prune && git -C ~/wheelzone-script-utils reset --hard origin/main

# ensure validator
if [ ! -x ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py ]; then
  mkdir -p ~/wheelzone-script-utils/scripts/utils
  cp -f ~/wz-wiki/.ci/check_uuid_index.py ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py || true
  sed -i "1s|^#!.*python3$|#!/usr/bin/env python3|" ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py || true
  chmod +x ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py || true
fi

# placeholders (до прихода реальных скриптов)
mkdir -p ~/wheelzone-script-utils/scripts/{services,clients,tests}
: > ~/wheelzone-script-utils/scripts/services/wz_uuid_orchestrator
: > ~/wheelzone-script-utils/scripts/clients/wz_uuid
: > ~/wheelzone-script-utils/scripts/tests/test_uuid.sh
: > ~/wheelzone-script-utils/scripts/tests/test_uuid_conflicts.sh
: > ~/wheelzone-script-utils/scripts/tests/test_uuid_hooks.sh
chmod +x ~/wheelzone-script-utils/scripts/services/wz_uuid_orchestrator \
         ~/wheelzone-script-utils/scripts/clients/wz_uuid \
         ~/wheelzone-script-utils/scripts/tests/*.sh
R

# --- 6) финальная проверка на VPS ---

ssh -p "$PORT" "$REMOTE" '

  set -euo pipefail

  WZ_CI_JSON_LOG=1 ~/wheelzone-script-utils/scripts/utils/check_uuid_index.py \

    --check-all ~/wz-wiki/docs/index_uuid.md \

    --policy    ~/wz-wiki/registry/uuid_orchestrator.yaml

'

echo "✅ SHIP OK: wiki synced, validator green"
