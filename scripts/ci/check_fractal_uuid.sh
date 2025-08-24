#!/data/data/com.termux/files/usr/bin/bash
# check_fractal_uuid.sh — падает, если есть файлы без fractal_uuid в первых 12 строках
set -Eeuo pipefail

MAX_DEPTH="${MAX_DEPTH:-12}"

is_binary() {
  local f="$1"
  if file -b --mime "$f" 2>/dev/null | grep -q 'charset=binary'; then return 0; fi
  if LC_ALL=C grep -Iq . "$f"; then return 1; else return 0; fi
}

skip_path() {
  case "$1" in
    */.git/*|*/__pycache__/*|*/node_modules/*|*/dist/*|*/build/*|*/.venv/*|*/.tox/*) return 0 ;;
    *.pyc|*.bak.*|*.backup.*) return 0 ;;
    *) return 1 ;;
  esac
}

should_check() {
  case "$1" in
    *.sh|*.bash|*.py|*.rb|*.pl|*.js|*.ts|*.go|*.java|*.c|*.h|*.hpp|*.cpp|*.cc|*.rs|*.php|*.lua|\
    *.yaml|*.yml|*.md|*.txt|*.service|*.timer|*.conf|*.env|*.ini|*.cfg|*.1|scripts/wz_chatend.sh|wz-wiki/scripts/wz_chatend.sh) return 0 ;;
    *) return 1 ;;
  esac
}

missing=()
while IFS= read -r -d '' f; do
  skip_path "$f" && continue
  should_check "$f" || continue
  is_binary "$f" && continue
  head -n 12 "$f" 2>/dev/null | grep -q 'fractal_uuid:' || missing+=("$f")
done < <(find . -type f -maxdepth "$MAX_DEPTH" -print0 2>/dev/null)

if [ "${#missing[@]}" -gt 0 ]; then
  printf '[WZ][FAIL] Files without fractal_uuid header (%d):\n' "${#missing[@]}"
  printf '%s\n' "${missing[@]}"
  exit 42
fi

printf '\033[1;92m[WZ][OK] fractal_uuid: all good\033[0m\n'
