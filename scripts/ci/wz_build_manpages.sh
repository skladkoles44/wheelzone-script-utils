#!/usr/bin/env bash
set -Eeuo pipefail
REPO="${REPO:-$HOME/wheelzone-script-utils}"
MANDIR="$REPO/docs/man"
OUTDIR="$REPO/docs/artifacts"
TS="$(date -u +%Y%m%d-%H%M%SZ)"
TAR="$OUTDIR/manpages-$TS.tar.gz"
SHA="$TAR.sha256"
INDEX="$OUTDIR/INDEX.md"

# Генерация (если есть генератор)
[ -x "$REPO/scripts/utils/wz_gen_manpages.sh" ] && "$REPO/scripts/utils/wz_gen_manpages.sh" || true

# Проверяем наличие .1
count="$(find "$MANDIR" -maxdepth 1 -type f -name '*.1' | wc -l | tr -d ' ')"
[ "$count" -gt 0 ] || { echo "[ERR] нет man-файлов в $MANDIR"; exit 3; }

mkdir -p "$OUTDIR"

# Упаковка: делаем glob внутри $MANDIR, чтобы не ловить 'Cannot stat'
(
  set -Eeuo pipefail
  cd "$MANDIR"
  shopt -s nullglob
  files=( *.1 )
  [ "${#files[@]}" -gt 0 ] || { echo "[ERR] пустой список *.1 после glob"; exit 4; }
  tar -czf "$TAR" "${files[@]}"
)

sha256sum "$TAR" > "$SHA"

# UUID sidecars for artifacts
$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_enforcer.sh "$REPO" fix >/dev/null 2>&1 || true
patched=1

# Обновить индекс (prepend)
TMP="$(mktemp)"
{
  echo "| Timestamp (UTC) | Archive | Size | SHA256 |"
  echo "|---|---|---|---|"
  SIZE="$(du -h "$TAR" | awk '{print $1}')"
  HASH="$(awk '{print $1}' "$SHA")"
  echo "| $TS | $(basename "$TAR") | $SIZE | \`$HASH\` |"
  if [ -f "$INDEX" ]; then tail -n +3 "$INDEX" || true; fi
} > "$TMP"
mv "$TMP" "$INDEX"

echo "[WZ] Built: $TAR"
echo "[WZ] Hash:  $SHA"
echo "[WZ] Index: $INDEX"

# Локальный автокоммит (может быть без пуша — отдельным шагом)
git -C "$REPO" add "$TAR" "$SHA" "$INDEX" || true
git -C "$REPO" commit -m "ci(docs): add manpages artifact $TS" || true
