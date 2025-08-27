#!/usr/bin/env bash
set -Eeuo pipefail

: "${PREFIX:=/data/data/com.termux/files/usr}"
SRC_DIR="$HOME/wheelzone-script-utils/docs/man"
DST_DIR="$PREFIX/share/man/man1"

ok()  { printf "\033[1;92m[WZ]\033[0m %s\n" "$*"; }
err() { printf "\033[1;91m[ERR]\033[0m %s\n" "$*" >&2; }

# 0) Проверки окружения
if ! command -v man >/dev/null 2>&1; then
  err "'man' не установлен. Команда: pkg install man"
  exit 1
fi
install -d -m 0755 "$DST_DIR"

# 1) Накатываем все .1 из docs/man
count=0
shopt -s nullglob
for src in "$SRC_DIR"/*.1; do
  base="$(basename "$src")"
  dst="$DST_DIR/${base}.gz"
  gzip -c "$src" > "$dst"
  chmod 0644 "$dst"
  ok "Установлено: $(basename "$dst")"
  count=$((count+1))
done
shopt -u nullglob

if [ "$count" -eq 0 ]; then
  err "Нет файлов *.1 в $SRC_DIR — нечего устанавливать."
  exit 2
fi

# 2) Обновляем индекс (если есть утилиты)
if command -v mandb >/dev/null 2>&1; then
  ok "Обновление mandb..."
  mandb -q || true
elif command -v makewhatis >/dev/null 2>&1; then
  ok "Обновление makewhatis..."
  makewhatis "$PREFIX/share/man" || true
else
  ok "Индекс man не обновлялся (mandb/makewhatis отсутствуют) — это ок для Termux."
fi

# 3) Быстрая проверка одной страницы (если есть)
if [ -f "$DST_DIR/check_gdrive.1.gz" ]; then
  ok "Проверка пути: $(man -w check_gdrive || echo 'не найдено в manpath')"
fi

ok "Готово: установлено страниц: $count"
