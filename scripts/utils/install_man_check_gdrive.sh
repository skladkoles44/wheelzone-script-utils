#!/usr/bin/env bash
set -Eeuo pipefail
: "${PREFIX:=${PREFIX:-/data/data/com.termux/files/usr}}"

MAN_SRC="$HOME/wheelzone-script-utils/docs/man/check_gdrive.1"
MAN_DIR="$PREFIX/share/man/man1"
MAN_DST="$MAN_DIR/check_gdrive.1.gz"

if ! command -v man >/dev/null 2>&1; then
  echo "[ERR] 'man' недоступен. Установи пакет: pkg install man" >&2
  exit 1
fi

install -d -m 0755 "$MAN_DIR"
# Сжимаем и ставим
gzip -c "$MAN_SRC" > "$MAN_DST"

# Обновлять whatis/mandb в Termux обычно не требуется; проверим доступность
echo "[WZ] man page установлена: $MAN_DST"
echo "[WZ] Проверка: man -w check_gdrive"
man -w check_gdrive || true
