#!/usr/bin/env bash
# fractal_uuid: $(date -Iseconds)-bootstrap-wz-sync-secrets
# title: WZ :: Secrets Sync (Drive→Git with md5 control)
# version: 1.0.0
# component: cron
# description: Автоматический синк базы wz-secrets.kdbx из Google Drive в wz-wiki с md5-контролем, сайдкаром и пушем в Git.
# updated_at: $(date -Iseconds)

set -Eeuo pipefail
IFS=$'\n\t'

REPO="$HOME/wz-wiki"
FILE="wz-secrets.kdbx"
SIDE="$REPO/$FILE.uuid.yaml"
REMOTE="gdrive:/WZSecrets/$FILE"

say(){ printf "\033[1;92m[WZ] %s\033[0m\n" "$*"; }

cd "$REPO"

say "Синхронизируем $FILE из Google Drive…"
rclone copy "$REMOTE" "$REPO" >/dev/null 2>&1 || { say "❌ rclone copy failed"; exit 1; }

MD5_NEW="$(md5sum "$FILE" | awk '{print $1}')"
MD5_OLD="$(grep '^md5:' "$SIDE" 2>/dev/null | awk '{print $2}' || true)"

if [ "$MD5_NEW" = "$MD5_OLD" ]; then
  say "Изменений нет, пуш не требуется."
  exit 0
fi

say "Изменение обнаружено, запрашиваем новый UUID…"
UUID="$(ssh -p 2222 root@79.174.85.106 'set -Eeuo pipefail
  . /root/.wz_uuid_env
  curl -sS --max-time 5 -H "Authorization: Bearer $WZ_UUID_TOKEN" \
    "http://127.0.0.1:9017/api/uuid/take?ns=wz:secrets&count=1" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)[\"ids\"][0])"')"

[ -n "$UUID" ] || { say "❌ UUID не получен"; exit 2; }

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

say "Обновляем $SIDE"
cat > "$SIDE" <<EOT
fractal_uuid: "$UUID"
file: "$FILE"
md5: "$MD5_NEW"
namespace: "wz:secrets"
source: "uuid-orchestrator@79.174.85.106"
created_at: "$STAMP"
EOT

say "Коммитим и пушим…"
git add "$FILE" "$SIDE"
git commit -m "backup(secrets): update kdbx + sidecar (uuid=$UUID)" >/dev/null || true
git pull --rebase origin main || true
git push origin main

say "Готово. md5=$MD5_NEW uuid=$UUID"
