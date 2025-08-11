#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
FILE="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend.sh"
BAK="$FILE.bak.$(date +%s)"

[ -f "$FILE" ] || { echo "[ERR] not found: $FILE"; exit 1; }
cp -f "$FILE" "$BAK"
echo "[i] backup: $BAK"

insert_sanitizer() {
  if grep -q 'sanitize_wz_path()' "$FILE"; then
    echo "[=] sanitizer already present"; return
  fi
  tmp="$(mktemp)"
  awk 'NR==1{print; next}
       NR==2{
         print "set -Eeuo pipefail"
         print ""
         print "# --- WZ path sanitizer (idempotent) ---"
         print "sanitize_wz_path(){"
         print "  local p=\"$1\""
         print "  p=\"${p#:}\""
         print "  case \"$p\" in"
         print "    \"~\"|\"~/\") p=\"$HOME/\";;"
         print "    \"~\"/*)      p=\"$HOME/${p#~/}\";;"
         print "  esac"
         print "  echo \"$p\" | sed -E '\''s#(^|[^:])//+#\***REMOVED***/#g'\''"
         print "}"
         print "# --- /sanitizer ---"
         next
       }
       { print }' "$FILE" > "$tmp"
  mv -f "$tmp" "$FILE"
  chmod +x "$FILE"
  echo "[i] sanitizer injected"
}

wrap_var_calls() {
  for V in inc_path nested_path include_path fpath; do
    if grep -q "\$$V" "$FILE"; then
      tmp="$(mktemp)"
      awk -v V="$V" '
        {
          line=$0
          if (line ~ "sanitize_wz_path\\(") { print line; next }
          gsub("\\$"V"\"", "$(sanitize_wz_path \\\"$" V "\\\")\"", line)
          print line
        }' "$FILE" > "$tmp"
      mv -f "$tmp" "$FILE"
      chmod +x "$FILE"
      echo "[i] wrapped: $V"
    fi
  done
}

insert_sanitizer
wrap_var_calls

if bash -n "$FILE"; then
  echo "[OK] bash -n passed"
else
  echo "[ERR] syntax error after patch — restoring backup"
  cp -f "$BAK" "$FILE"
  exit 2
fi

echo "[DONE] patch applied"
