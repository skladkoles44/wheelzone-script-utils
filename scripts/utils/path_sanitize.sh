#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:39+03:00-4179961135
# title: path_sanitize.sh
# component: .
# updated_at: 2025-08-26T13:19:39+03:00

# WZ Path Sanitize v1.0 — убираем ведущие ":" и разворачиваем "~" → $HOME
set -Eeuo pipefail

wz_sanitize_path() {
  local p
  p="$(cat - | tr -d '\r')"
  p="${p#:}"   # убрать ведущие двоеточия
  case "$p" in
    "~"|"/~"| "~/") p="$HOME/";;
    "~"/*)          p="$HOME/${p#~/}";;
  esac
  echo "$p" | sed -E 's#(^|[^:])//+#***REMOVED***/#g'
}

wz_sanitize_file() {
  local in="$1" out="$2"
  [ -f "$in" ] || { echo "no input: $in" >&2; return 1; }
  local H="$HOME"
  sed -E \
    -e 's#(^|[[( ])[:]+(/|~)#***REMOVED***#g' \
    -e "s#(^|[[( ])~/#***REMOVED***${H}/#g" \
    "$in" > "$out"
}
export -f wz_sanitize_path wz_sanitize_file
