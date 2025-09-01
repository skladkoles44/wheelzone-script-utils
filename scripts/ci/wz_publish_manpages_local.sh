#!/usr/bin/env bash
set -Eeuo pipefail
WZSU="$HOME/wheelzone-script-utils"
WZWIKI="$HOME/wz-wiki"
MANDIR="$WZSU/docs/man"
WIKI_MAN="$WZWIKI/docs/man"
WIKI_ART="$WZWIKI/docs/artifacts/manpages"

mkdir -p "$WIKI_MAN" "$WIKI_ART"

# Синхронизация самих .1 (полные тексты — полезно для чтения на GitHub)
rsync -a --delete "$MANDIR/" "$WIKI_MAN/"

# Синхронизация arifacts (tar.gz + sha256 + INDEX.md)
rsync -a "$WZSU/docs/artifacts/" "$WIKI_ART/"

# Индекс в wiki/README (микро-якорь)
INDEX_LOCAL="$WZSU/docs/artifacts/INDEX.md"
if [ -f "$INDEX_LOCAL" ]; then
  mkdir -p "$WZWIKI/docs/artifacts"
  cp -f "$INDEX_LOCAL" "$WZWIKI/docs/artifacts/INDEX.md"
fi

echo "[WZ] WIKI updated: docs/man + docs/artifacts/manpages"
