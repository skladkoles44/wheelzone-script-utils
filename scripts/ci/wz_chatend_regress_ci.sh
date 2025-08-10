#!/usr/bin/env bash
# WZ ChatEnd Regress CI v1.0 (for Drone)
set -Eeuo pipefail

echo "[i] ENV:"
env | sort

# 1) Подтягиваем wz-wiki (ожидается приватный, нужен доступный токен/ключ в Drone secrets)
: "${WZ_WIKI_GIT_URL:?Missing WZ_WIKI_GIT_URL}"
: "${GIT_SSH_COMMAND:=}"

echo "[i] clone wz-wiki..."
rm -rf ./wz-wiki
git clone --depth=1 "$WZ_WIKI_GIT_URL" ./wz-wiki

# 2) Структура теста
mkdir -p ~/.wz_logs ~/.wz_tmp ./wzbuffer/chatend_test
cat > ./wzbuffer/chatend_test/nested.md <<'MD'
# Nested
Content OK
MD
cat > ./wzbuffer/chatend_test/main_space.md <<'MD'
# Main
Include: ~/wzbuffer/chatend_test/nested.md
MD
cat > ./wzbuffer/chatend_test/main_nospace.md <<'MD'
# Main
Include:~/wzbuffer/chatend_test/nested.md
MD
cat > ./wzbuffer/chatend_test/main_homevar.md <<'MD'
# Main
Include:$HOME/wzbuffer/chatend_test/nested.md
MD

# 3) Кладём безопасную обёртку и оригинал (эмулируем локальную структуру)
mkdir -p ~/wheelzone-script-utils/scripts/cli
mkdir -p ~/wheelzone-script-utils/scripts/utils
# Ожидается, что этот репозиторий уже чек-аутнут Drone-ом в $DRONE_WORKSPACE
# Копируем из текущего src:
cp -R ./scripts ~/wheelzone-script-utils/ 2>/dev/null || true
cp -R ./cli ~/wheelzone-script-utils/ 2>/dev/null || true

SAFE="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh"
ORIG_LOCAL="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend.sh"
ORIG_WIKI1="$PWD/wz-wiki/scripts/wz_chatend.sh"
ORIG_WIKI2="$PWD/wz-wiki/wz-wiki/scripts/wz_chatend.sh"

# Если оригинал лежит в wz-wiki — запускаем оттуда
if [ -x "$ORIG_WIKI1" ]; then
  sed -i "s#^CHATEND_ORIG=.*#CHATEND_ORIG=\"$ORIG_WIKI1\"#g" "$SAFE" || true
elif [ -x "$ORIG_WIKI2" ]; then
  sed -i "s#^CHATEND_ORIG=.*#CHATEND_ORIG=\"$ORIG_WIKI2\"#g" "$SAFE" || true
elif [ -x "$ORIG_LOCAL" ]; then
  sed -i "s#^CHATEND_ORIG=.*#CHATEND_ORIG=\"$ORIG_LOCAL\"#g" "$SAFE" || true
else
  echo "[ERR] wz_chatend.sh not found in expected locations" >&2
  exit 2
fi
chmod +x "$SAFE" || true

# 4) Запускаем регресс (без exec)
: > ~/.wz_logs/fractal_chatend.log || true
"$SAFE" --verbose --no-exec --auto "$PWD/wzbuffer/chatend_test/main_space.md" || true
"$SAFE" --verbose --no-exec --auto "$PWD/wzbuffer/chatend_test/main_nospace.md" || true
"$SAFE" --verbose --no-exec --auto "$PWD/wzbuffer/chatend_test/main_homevar.md" || true

# 5) Проверка аномалий и "Не найден файл"
FRAC_TAIL="$(tail -n 200 ~/.wz_logs/fractal_chatend.log 2>/dev/null || true)"
ANOM="$(printf "%s\n" "$FRAC_TAIL" | grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME' || true)"
NOFILE="$(printf "%s\n" "$FRAC_TAIL" | grep -n 'Не найден файл' || true)"

echo "=== CI ChatEnd Sanitize Regress ==="
echo "[anomalies]"; if [ -n "$ANOM" ]; then printf "%s\n" "$ANOM"; else echo "<none>"; fi
echo "[nofile]";   if [ -n "$NOFILE" ]; then printf "%s\n" "$NOFILE"; else echo "<none>"; fi

# 6) Строгая политика
[ -z "$ANOM" ] && [ -z "$NOFILE" ] && echo "[OK] CI regress passed"
