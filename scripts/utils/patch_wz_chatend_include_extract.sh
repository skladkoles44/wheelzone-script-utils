#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:38+03:00-2603610093
# title: patch_wz_chatend_include_extract.sh
# component: .
# updated_at: 2025-08-26T13:19:38+03:00

set -Eeuo pipefail

inject_extract_guard() {
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }
  local BAK="$F.bak.$(date +%s)"
  cp -f "$F" "$BAK"
  echo "[i] backup: $BAK"

  # Вставляем защитную переинициализацию nested_file сразу после первой проверки include-строки
  # Идемпотентность: не вставлять повторно, если уже есть sed-очистка Include:
  if grep -q 'sed -E .*^Include:' "$F"; then
    echo "[=] include-extract guard already present → $F"
  else
    awk '
      BEGIN{ins=0}
      {
        if (!ins && $0 ~ /Include:/) {
          print
          print "      # extract nested_file from Include:… (remove label + spaces)"
          print "      nested_file=\"$(printf '%s\n' \"$line\" | sed -E 's/^Include:[[:space:]]*//')\""
          print "      nested_file=\"$(wz_sanitize_path \"$nested_file\")\""
          ins=1
          next
        }
        print
      }' "$F" > "$F.tmp" && mv -f "$F.tmp" "$F"
    echo "[i] include-extract guard injected → $F"
  fi

  if bash -n "$F"; then
    echo "[OK] bash -n: $F"
  else
    echo "[ERR] syntax: restore $BAK"
    cp -f "$BAK" "$F"
    return 2
  fi
}

for F in \
  "$HOME/wz-wiki/scripts/wz_chatend.sh" \
  "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
do
  inject_extract_guard "$F"
done
