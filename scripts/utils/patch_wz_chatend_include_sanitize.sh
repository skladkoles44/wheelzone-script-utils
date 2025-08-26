#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:38+03:00-3776704400
# title: patch_wz_chatend_include_sanitize.sh
# component: .
# updated_at: 2025-08-26T13:19:38+03:00

set -Eeuo pipefail

patch_one() {
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }

  local BAK="$F.bak.$(date +%s)"
  cp -f "$F" "$BAK"
  echo "[i] backup: $BAK"

  # 1) Вставим sanitizer, если его ещё нет
  if ! grep -q 'wz_sanitize_path()' "$F"; then
    awk 'NR==1{print; next}
         NR==2{
           print "set -Eeuo pipefail"
           print ""
           print "# --- WZ path sanitizer ---"
           print "wz_sanitize_path(){"
           print "  local p=\"$1\""
           print "  p=\"${p#:}\"         # убрать ведущие двоеточия"
           print "  case \"$p\" in"
           print "    \"~\"|\"~/\") p=\"$HOME/\";;"
           print "    \"~\"/*)      p=\"$HOME/${p#~/}\";;"
           print "  esac"
           print "  echo \"$p\" | sed -E '\''s#(^|[^:])//+#\***REMOVED***/#g'\''"
           print "}"
           print "# --- /sanitizer ---"
           next
         }
         { print }' "$F" > "$F.tmp1"
    mv -f "$F.tmp1" "$F"
    chmod +x "$F"
    echo "[i] sanitizer injected → $F"
  else
    echo "[=] sanitizer already present in $F"
  fi

  # 2) Перед первой проверкой if [...$nested_file...] — добавим sanitize
  if grep -qE 'if[[:space:]]*\[[^]]*\$nested_file[^]]*\]' "$F"; then
    awk '
      BEGIN{ins=0}
      {
        if (!ins && $0 ~ /if[[:space:]]*\[[^]]*\$nested_file[^]]*\]/) {
          print "nested_file=\"$(wz_sanitize_path \"$nested_file\")\""
          ins=1
        }
        print
      }' "$F" > "$F.tmp2"
    mv -f "$F.tmp2" "$F"
    chmod +x "$F"
    echo "[i] sanitize line added before first if [...] \$nested_file in $F"
  else
    echo "[WARN] no if [...] \$nested_file check found in $F (skipped add)"
  fi

  # 3) Безопасная проверка синтаксиса
  if bash -n "$F"; then
    echo "[OK] bash -n passed for $F"
  else
    echo "[ERR] syntax error, restore backup: $BAK"
    cp -f "$BAK" "$F"
    return 2
  fi
}

for F in \
  "$HOME/wz-wiki/scripts/wz_chatend.sh" \
  "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
do
  patch_one "$F"
done
