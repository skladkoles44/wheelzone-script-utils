#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Целевые расширения (через пробел)
TARGET_EXT="${TARGET_EXT:-md yml yaml service timer conf env ini cfg txt 1}"
CHANGED_FILE="${CHANGED_FILE:-$HOME/wzbuffer/_wz_uuid_changed.txt}"
IGN=".wz/fractal_uuid_ignore.txt"

comment_prefix(){
  local f="$1" ext="${f##*.}"
  case "$ext" in
    sh|bash|py|rb|pl|js|ts|go|java|c|h|hpp|cpp|cc|rs|php|lua|conf|service|timer|env|ini|cfg|yml|yaml|md|txt) echo "#";;
    1) echo ".\\\"";; # groff man(1)
    *) echo "#";;
  esac
}
has_uuid(){ head -n 12 "$1" 2>/dev/null | grep -q 'fractal_uuid:'; }
has_uuid_in_frontmatter(){ has_uuid "$1"; }

gen_uuid(){ python3 - "$1" <<'PY'
import uuid, os, sys
p = os.path.relpath(sys.argv[1], start='.')
print(uuid.uuid5(uuid.NAMESPACE_URL, "wz://"+p))
PY
}

prepend_uuid_header(){
  local f="$1" pfx uid ts tmp mode exe=0
  pfx="$(comment_prefix "$f")"
  uid="$(gen_uuid "$f")"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  mode="$(stat -c '%a' "$f" 2>/dev/null || echo 644)"
  [ -x "$f" ] && exe=1
  {
    printf '%s fractal_uuid: %s\n' "$pfx" "$uid"
    printf '%s added: %s\n' "$pfx" "$ts"
    cat "$f"
  } > "$tmp"
  cat "$tmp" > "$f"
  chmod "$mode" "$f" || true
  [ "$exe" -eq 1 ] && chmod +x "$f" || true
  rm -f "$tmp"
}

path_ignored(){
  local f="$1"
  [ -f "$IGN" ] || return 1
  while IFS= read -r pat; do
    [[ -z "$pat" || "$pat" =~ ^# ]] && continue
    [[ "$f" == $pat ]] && return 0
  done < "$IGN"
  return 1
}

normalize_list_to_nl(){
  local in="$1" out="$2"
  if [ -s "$in" ] && grep -q $'\0' "$in" 2>/dev/null; then
    awk 'BEGIN{RS="\0"; ORS="\n"} {gsub(/^\.\//,""); if(length($0)) print}' "$in" > "$out"
  else
    sed 's#^\./##' "$in" | awk 'NF' > "$out"
  fi
}

append_to_changed(){ printf '%s\n' "$1" >> "$CHANGED_FILE"; }

find_targets(){
  # формируем -name паттерны динамически по TARGET_EXT
  local base="${1:-.}"
  local expr=()
  for e in $TARGET_EXT; do
    expr+=( -iname "*.${e}" -o )
  done
  # убираем последний -o
  unset 'expr[${#expr[@]}-1]'
  # shellcheck disable=SC2068
  find "$base" -type f \( ${expr[@]} \) -print0 2>/dev/null
}

ensure_dir_have_uuid(){
  local base="${1:-.}"
  : > "$CHANGED_FILE"; chmod 600 "$CHANGED_FILE" || true
  while IFS= read -r -d '' f; do
    path_ignored "$f" && continue
    has_uuid "$f" && continue
    prepend_uuid_header "$f"
    append_to_changed "$f"
  done < <(find_targets "$base")
  if [ -s "$CHANGED_FILE" ]; then
    # безопасное добавление (пути с пробелами)
    tr '\n' '\0' < "$CHANGED_FILE" | xargs -0 -I{} git add -- "{}" 2>/dev/null || git add --all
    git commit -m "fractal_uuid: add headers in ${base}" || true
  fi
}

ensure_files_have_uuid(){
  local -a to_add=()
  : > "$CHANGED_FILE"; chmod 600 "$CHANGED_FILE" || true
  for f in "$@"; do
    [ -f "$f" ] || continue
    path_ignored "$f" && continue
    has_uuid "$f" && continue
    prepend_uuid_header "$f"
    append_to_changed "$f"
    to_add+=("$f")
  done
  [ "${#to_add[@]}" -gt 0 ] && git add -- "${to_add[@]}" && git commit -m "fractal_uuid: add headers (targeted)" || true
}

ensure_all_have_uuid(){
  # удобная кнопка по типовым папкам
  for d in scripts configs docs registry .; do
    [ -d "$d" ] && ensure_dir_have_uuid "$d"
  done
}

print_green_summary(){
  if [ -s "$CHANGED_FILE" ]; then
    local CLEAN="$CHANGED_FILE.clean"
    normalize_list_to_nl "$CHANGED_FILE" "$CLEAN"
    printf '\033[1;92m=== WZ :: fractal_uuid ADDED ===\033[0m\n'
    nl -ba "$CLEAN"
    command -v termux-clipboard-set >/dev/null 2>&1 && termux-clipboard-set < "$CLEAN" || true
  else
    printf '\033[1;92m[WZ] Всё чисто\033[0m\n'
  fi
}

export TARGET_EXT CHANGED_FILE
export -f comment_prefix has_uuid has_uuid_in_frontmatter gen_uuid prepend_uuid_header \
          path_ignored normalize_list_to_nl append_to_changed find_targets \
          ensure_dir_have_uuid ensure_files_have_uuid ensure_all_have_uuid print_green_summary
