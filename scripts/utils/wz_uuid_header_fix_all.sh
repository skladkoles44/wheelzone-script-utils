#!/usr/bin/env bash
# fractal_uuid: will-be-prepended
# title: wz_uuid_header_fix_all.sh
# version: 1.4.1
# component: utils
# description: prepend/normalize *fractal_uuid* headers for sh/bats/yaml/md (strict: only generate_fractal_uuid)
# updated_at: 2025-08-26

set -Eeuo pipefail
IFS=$'\n\t'

MODE="dry"  # dry|write
ROOT="${1:-.}"
shift || true

case "${1:-}" in
  --write) MODE="write" ;;
  --dry-run|"") ;;
  *) echo "Usage: $0 [root-dir] [--write|--dry-run]"; exit 1 ;;
esac

cd "$ROOT" || { echo "Cannot cd to $ROOT" >&2; exit 1; }

# === Canon bridge (НЕ генератор — только подключение канона) ===
BRIDGE="$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_bridge.sh"
if [ -r "$BRIDGE" ]; then
  # shellcheck disable=SC1090
  . "$BRIDGE" || { echo "ERR: failed to source bridge: $BRIDGE" >&2; exit 2; }
fi

# === Strict: разрешён только generate_fractal_uuid ===
need_canon() {
  command -v generate_fractal_uuid >/dev/null 2>&1 \
    || { echo "ERR: generate_fractal_uuid not found. Ensure wz_uuid_bridge points to wz_history_core.sh" >&2; exit 3; }
}

# === Ignore-list ===
IGN=".wz/fractal_uuid_ignore.txt"
in_ignore() {
  local f="$1"
  [ -r "$IGN" ] || return 1
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    [[ "$pat" =~ ^# ]] && continue
    case "$f" in
      $pat) return 0 ;;
    esac
  done <"$IGN"
  return 1
}

# === Генерация значения только каноном ===
gen_fuuid() {
  need_canon
  generate_fractal_uuid "uuid-header:$(basename "$1")"
}

# === Безопасные атомарные записи с сохранением прав ===
_atomically_replace() {
  local src="$1" dst="$2" tmp
  tmp="$(mktemp -p "$(dirname "$dst")" 2>/dev/null || mktemp 2>/dev/null || echo "${dst}.tmp")"
  cat "$src" >"$tmp"
  if command -v stat >/dev/null 2>&1; then
    if stat -c "%a" "$dst" >/dev/null 2>&1; then
      chmod "$(stat -c "%a" "$dst")" "$tmp" 2>/dev/null || true
    elif stat -f "%Lp" "$dst" >/dev/null 2>&1; then
      chmod "$(stat -f "%Lp" "$dst")" "$tmp" 2>/dev/null || true
    fi
  fi
  cat "$tmp" >"$dst" && rm -f "$tmp" || { echo "Error writing to $dst" >&2; rm -f "$tmp"; return 1; }
}

add_header_sh() {
  local f="$1" tmp uuid comp
  uuid="$(gen_fuuid "$f")"
  tmp="$(mktemp -p "$(dirname "$f")" 2>/dev/null || mktemp 2>/dev/null || echo "${f}.tmp")"
  comp="$(printf '%s' "$f" | awk -F/ '{print $2}')"

  if head -n1 "$f" | grep -q '^#!'; then
    {
      head -n1 "$f"
      printf '# fractal_uuid: %s\n' "$uuid"
      printf '# title: %s\n' "$(basename "$f")"
      printf '# version: 1.0.0\n'
      printf '# component: %s\n' "${comp:-utils}"
      printf '# updated_at: %s\n\n' "$(date -Iseconds)"
      tail -n +2 "$f"
    } >"$tmp"
  else
    {
      printf '#!/usr/bin/env bash\n'
      printf '# fractal_uuid: %s\n' "$uuid"
      printf '# title: %s\n' "$(basename "$f")"
      printf '# version: 1.0.0\n'
      printf '# component: %s\n' "${comp:-utils}"
      printf '# updated_at: %s\n\n' "$(date -Iseconds)"
      cat "$f"
    } >"$tmp"
  fi

  _atomically_replace "$tmp" "$f"
  rm -f "$tmp"
}

add_header_yaml() {
  local f="$1" tmp uuid
  uuid="$(gen_fuuid "$f")"
  tmp="$(mktemp -p "$(dirname "$f")" 2>/dev/null || mktemp 2>/dev/null || echo "${f}.tmp")"
  if head -n1 "$f" | grep -qE '^#|^---'; then
    printf 'fractal_uuid: %s\n' "$uuid" >"$tmp"
    cat "$f" >>"$tmp"
  else
    printf '---\nfractal_uuid: %s\n' "$uuid" >"$tmp"
    cat "$f" >>"$tmp"
  fi
  _atomically_replace "$tmp" "$f"
  rm -f "$tmp"
}

add_header_md() {
  local f="$1" tmp tmp2 uuid
  uuid="$(gen_fuuid "$f")"
  # 🔧 bugfix: закрытая кавычка и скобка
  tmp="$(mktemp -p "$(dirname "$f")" 2>/dev/null || mktemp 2>/dev/null || echo "${f}.tmp")"

  if head -n1 "$f" 2>/dev/null | grep -q '^---$'; then
    if awk 'BEGIN{inFM=0; found=0}
            NR==1 && /^---$/ {inFM=1; next}
            inFM && tolower($0) ~ /^fractal_uuid:/ {found=1}
            inFM && /^---$/ {inFM=0; exit}
            END{exit found}' "$f"; then
      return 0
    fi
    tmp2="$(mktemp 2>/dev/null || echo "${tmp}.2")"
    awk -v uid="$uuid" '
      NR==1 && /^---$/ { print; print "fractal_uuid: " uid; next }
      { print }
    ' "$f" >"$tmp2"
    _atomically_replace "$tmp2" "$f"
    rm -f "$tmp2"
  else
    printf '---\nfractal_uuid: %s\n---\n\n' "$uuid" >"$tmp"
    cat "$f" >>"$tmp"
    _atomically_replace "$tmp" "$f"
  fi
  rm -f "$tmp"
}

needs_fix() {
  local f="$1" ext="${f##*.}" base="${f%.*}"
  [[ "$(basename "$f")" == .* ]] && return 1
  [[ "$f" == *~ ]] && return 1
  [[ "$f" == *.tmp ]] && return 1
  in_ignore "$f" && return 1

  case "$ext" in
    sh|bats)
      head -n15 "$f" 2>/dev/null | grep -qi '^#.*fractal_uuid:' && return 1
      return 0 ;;
    sh.bak)
      head -n15 "$f" 2>/dev/null | grep -qi '^#.*fractal_uuid:' && return 1
      return 0 ;;
    yml|yaml)
      head -n10 "$f" 2>/dev/null | grep -qi '^\s*fractal_uuid:' && return 1
      return 0 ;;
    md)
      if head -n1 "$f" 2>/dev/null | grep -q '^---$'; then
        awk 'BEGIN{inFM=0; found=0}
             NR==1 && /^---$/ {inFM=1; next}
             inFM && tolower($0) ~ /^fractal_uuid:/ {found=1}
             inFM && /^---$/ {inFM=0; exit}
             END{exit found}' "$f" 2>/dev/null && return 1 || return 0
      else
        head -n10 "$f" 2>/dev/null | grep -qi '^fractal_uuid:' && return 1
        return 0
      fi ;;
    *)
      if [[ "$ext" == "$base" ]] || [[ "$f" != *.* ]]; then
        if file "$f" 2>/dev/null | grep -q "shell script"; then
          head -n15 "$f" 2>/dev/null | grep -qi '^#.*fractal_uuid:' && return 1
          return 0
        fi
      fi
      return 1 ;;
  esac
}

process_file() {
  local f="$1" ext="${f##*.}" base="${f%.*}"
  needs_fix "$f" || return 1

  if [ "$MODE" = "dry" ]; then
    echo "[DRY] $f"
    return 0
  fi

  case "$ext" in
    sh|bats|sh.bak) add_header_sh "$f" && echo "[FIXED] $f"; return 0 ;;
    yml|yaml)       add_header_yaml "$f" && echo "[FIXED] $f"; return 0 ;;
    md)             add_header_md "$f" && echo "[FIXED] $f"; return 0 ;;
    *)
      if [[ "$ext" == "$base" ]] || [[ "$f" != *.* ]]; then
        if file "$f" 2>/dev/null | grep -q "shell script"; then
          add_header_sh "$f" && echo "[FIXED] $f"; return 0
        fi
      fi
      return 1 ;;
  esac
}

gather_candidates() {
  if command -v find >/dev/null 2>&1; then
    find . -type f -not -path '*/\.git/*' -not -path '*/\.*' \
      \( -name '*.sh' -o -name '*.bats' -o -name '*.yml' -o -name '*.yaml' -o -name '*.md' -o -name '*.sh.bak' \) -print
    find . -type f -executable -not -path '*/\.git/*' -not -path '*/\.*'
  else
    for pattern in '*.sh' '*.bats' '*.yml' '*.yaml' '*.md' '*.sh.bak'; do
      find . -maxdepth 3 -name "$pattern" -not -path '*/\.git/*' -not -path '*/\.*' 2>/dev/null || true
    done
  fi
}

main() {
  echo "Scanning for files without *fractal_uuid* headers in: $(pwd)"
  need_canon
  local COUNT=0
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    if process_file "$f"; then
      COUNT=$((COUNT + 1))
    fi
  done < <(gather_candidates | sort -u)

  if [ "$MODE" = "write" ]; then
    echo "Total files fixed: $COUNT"
  else
    echo "Total files that would be fixed: $COUNT (use --write to apply changes)"
  fi
}

main "$@"
