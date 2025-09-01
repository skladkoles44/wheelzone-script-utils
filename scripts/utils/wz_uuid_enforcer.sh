#!/usr/bin/env bash
set -Eeuo pipefail
REPO="${1:-$HOME/wheelzone-script-utils}"
MODE="${2:-auto}" # auto|check|fix
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

is_text() { case "$1" in
  *.md|*.markdown|*.1|*.txt|*.yaml|*.yml) return 0;;
  *) return 1;;
esac; }

add_uuid_md() {
  local f="$1"
  # если уже есть fractal_uuid в первых 20 строках — пропускаем
  if head -n 20 "$f" | grep -qi 'fractal_uuid:'; then return 0; fi
  # если уже есть YAML front matter — вставим внутрь
  if head -n1 "$f" | grep -q '^---\s*$'; then
    tmp="$(mktemp)"
    { echo 'fractal_uuid: '"$(uuidgen | tr 'A-Z' 'a-z')"; sed '1d' "$f"; } | awk 'NR==1{print "---"} {print} END{print "---"}' > "$tmp"
    mv "$tmp" "$f"
  else
    tmp="$(mktemp)"
    {
      echo '---'
      echo 'fractal_uuid: '"$(uuidgen | tr 'A-Z' 'a-z')"
      echo '---'
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
  fi
}

add_uuid_roff() {
  local f="$1"
  # roff-комментарии начинаются с .\"
  if head -n 20 "$f" | grep -qi 'fractal_uuid:'; then return 0; fi
  tmp="$(mktemp)"
  {
    echo '.\" fractal_uuid: '"$(uuidgen | tr 'A-Z' 'a-z')"
    cat "$f"
  } > "$tmp"
  mv "$tmp" "$f"
}

make_sidecar() {
  local bin="$1"
  local side="${bin}.meta.yaml"
  # если есть — проверим наличие fractal_uuid
  if [ -f "$side" ] && grep -qi 'fractal_uuid:' "$side"; then return 0; fi
  local uuid="$(uuidgen | tr 'A-Z' 'a-z')"
  local base="$(basename "$bin")"
  local sha=""
  if [[ "$bin" == *.sha256 ]]; then
    sha="$(awk '{print $1}' "$bin" 2>/dev/null || true)"
  elif [[ "$bin" == *.tar.gz ]]; then
    sha="$(sha256sum "$bin" | awk '{print $1}')"
  fi
  cat > "$side" <<YML
fractal_uuid: $uuid
title: $base
type: artifact
linked_file: $base
timestamp: $NOW
sha256: ${sha:-null}
YML
}

scan_and_fix() {
  local root="$1"
  local changed=0
  # Текстовые
  while IFS= read -r -d '' f; do
    case "$f" in
      *.md|*.markdown|*.yaml|*.yml) add_uuid_md "$f"; changed=$((changed+1));;
      *.1) add_uuid_roff "$f"; changed=$((changed+1));;
    esac
  done < <(find "$root/docs" -type f \( -name '*.md' -o -name '*.markdown' -o -name '*.yaml' -o -name '*.yml' -o -name '*.1' \) -print0)

  # Бинарные артефакты
  while IFS= read -r -d '' b; do
    make_sidecar "$b"; changed=$((changed+1))
  done < <(find "$root/docs/artifacts" -type f \( -name '*.tar.gz' -o -name '*.sha256' \) -print0)

  echo "$changed"
}

scan_and_check() {
  local root="$1"; local missing=0
  # Текстовые
  while IFS= read -r -d '' f; do
    if ! head -n 30 "$f" | grep -qi 'fractal_uuid:'; then
      echo "[MISS] $f"; missing=$((missing+1))
    fi
  done < <(find "$root/docs" -type f \( -name '*.md' -o -name '*.markdown' -o -name '*.yaml' -o -name '*.yml' -o -name '*.1' \) -print0)
  # Бинари — sidecar
  while IFS= read -r -d '' b; do
    local side="${b}.meta.yaml"
    if [ ! -f "$side" ] || ! grep -qi 'fractal_uuid:' "$side"; then
      echo "[MISS] sidecar for $b"; missing=$((missing+1))
    fi
  done < <(find "$root/docs/artifacts" -type f \( -name '*.tar.gz' -o -name '*.sha256' \) -print0)
  echo "$missing"
}

case "$MODE" in
  auto|fix)
    changed="$(scan_and_fix "$REPO")"
    # добавим в индекс Git, если внутри коммита
    if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git -C "$REPO" add -A || true
    fi
    echo "[UUID] changed=$changed"
    ;;
  check)
    miss="$(scan_and_check "$REPO")"
    echo "[UUID] missing=$miss"
    [ "$miss" -eq 0 ] || exit 3
    ;;
  *)
    echo "Usage: $(basename "$0") [REPO] [auto|fix|check]"
    exit 2
    ;;
esac
