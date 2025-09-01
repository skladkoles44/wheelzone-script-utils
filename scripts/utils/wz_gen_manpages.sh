#!/usr/bin/env bash
set -Eeuo pipefail
REPO="${REPO:-$HOME/wheelzone-script-utils}"
SRC_DIRS=("$REPO/scripts/utils" "$REPO/cli")
DST_DIR="$REPO/docs/man"
mkdir -p "$DST_DIR"

gen_for() {
  local sh="$1"; local tmp="$(mktemp)"
  # Читаем поля
  local NAME SECTION VERSION DATE AUTHOR SYNOPSIS DESC
  NAME=$(grep -m1 '^# man: name='      "$sh" | cut -d= -f2- || true)
  [ -n "$NAME" ] || return 0  # нет аннотаций — пропуск
  SECTION=$(grep -m1 '^# man: section=' "$sh" | cut -d= -f2- || echo "1")
  VERSION=$(grep -m1 '^# man: version=' "$sh" | cut -d= -f2- || echo "0.1")
  DATE=$(grep -m1 '^# man: date='       "$sh" | cut -d= -f2- || date -I)
  AUTHOR=$(grep -m1 '^# man: author='   "$sh" | cut -d= -f2- || echo "WheelZone")
  SYNOPSIS=$(grep -m1 '^# man: synopsis=' "$sh" | cut -d= -f2- || echo "$NAME")
  DESC=$(grep -m1 '^# man: description=' "$sh" | cut -d= -f2- || echo "$NAME utility")

  {
    echo ".TH ${NAME^^} ${SECTION} \"$DATE\" \"WheelZone\" \"User Commands\""
    echo ".SH NAME"
    echo "$NAME \\- $DESC"
    echo
    echo ".SH SYNOPSIS"
    echo ".B $SYNOPSIS"
    echo
    echo ".SH DESCRIPTION"
    echo "$DESC"
    echo
    if grep -q '^# man: options=' "$sh"; then
      echo ".SH OPTIONS"
      grep '^# man: options=' "$sh" | cut -d= -f2- | while read -r line; do
        echo "$line"
        echo ".br"
      done
      echo
    fi
    if grep -q '^# man: exit=' "$sh"; then
      echo ".SH EXIT STATUS"
      grep '^# man: exit=' "$sh" | cut -d= -f2- | while read -r line; do
        echo "$line"
        echo ".br"
      done
      echo
    fi
    echo ".SH FILES"
    echo "$sh"
    echo "$DST_DIR/${NAME}.${SECTION}"
    echo
    echo ".SH SEE ALSO"
    echo "rclone(1)"
    echo
    echo ".SH AUTHOR"
    echo "$AUTHOR"
    echo
    echo ".SH VERSION"
    echo "v$VERSION"
  } > "$tmp"

  mv "$tmp" "$DST_DIR/${NAME}.${SECTION}"
  printf "\033[1;92m[WZ]\033[0m Generated man: %s\n" "$DST_DIR/${NAME}.${SECTION}"
}

for d in "${SRC_DIRS[@]}"; do
  [ -d "$d" ] || continue
  shopt -s nullglob
  for sh in "$d"/*.sh; do gen_for "$sh"; done
  shopt -u nullglob
done
