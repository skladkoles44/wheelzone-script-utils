#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
MAX_DEPTH="${MAX_DEPTH:-12}"
IGN=".wz/fractal_uuid_ignore.txt"

path_ignored(){ local f="$1"; [ -f "$IGN" ] || return 1
  while IFS= read -r pat; do [[ -z "$pat" || "$pat" =~ ^# ]] && continue; [[ "$f" == $pat ]] && return 0; done < "$IGN"
  return 1
}
is_binary(){ file -b --mime "$1" 2>/dev/null | grep -q 'charset=binary' && return 0; LC_ALL=C grep -Iq . "$1" || return 0; return 1; }
should_check(){
  case "$1" in
    *.md|*.yml|*.yaml|*.sh|*.service|*.timer|*.conf|*.env|*.ini|*.cfg|*.txt|*.1) return 0 ;;
    *) return 1 ;;
  esac
}
missing=()
while IFS= read -r -d '' f; do
  path_ignored "$f" && continue
  should_check "$f" || continue
  is_binary "$f" && continue
  head -n 12 "$f" 2>/dev/null | grep -q 'fractal_uuid:' || missing+=("$f")
done < <(find . -type f -maxdepth "$MAX_DEPTH" -print0 2>/dev/null)

if [ "${#missing[@]}" -gt 0 ]; then
  printf '[WZ][FAIL] Missing fractal_uuid (%d):\n' "${#missing[@]}"
  printf '%s\n' "${missing[@]}"
  exit 42
fi
printf '\033[1;92m[WZ][OK] fractal_uuid headers present\033[0m\n'
