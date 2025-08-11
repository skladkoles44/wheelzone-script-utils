#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

patch_file() {
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }
  local BAK="$F.bak.$(date +%s)"
  cp -f "$F" "$BAK"
  echo "[i] backup: $BAK"

  # 1) вставить/обновить wz_sanitize_path()
  if grep -q 'wz_sanitize_path()' "$F"; then
    # заменим тело функции на v2 (через sed диапазон)
    awk '
      BEGIN{infn=0}
      /^wz_sanitize_path\(\)\s*\{/ { print; infn=1; print "  local p=\"$1\""; print "  # 1) срезать любые ведущие двоеточия"; print "  while [ \"${p:0:1}\" = \":\" ]; do p=\"${p#:}\"; done"; print "  # 2) убрать ведущие пробелы"; print "  p=\"${p#${p%%[![:space:]]*}}\""; print "  # 3) ~ → $HOME"; print "  case \"$p\" in"; print "    \"~\"|\"~/\") p=\"$HOME/\";;"; print "    \"~\"/*)      p=\"$HOME/${p#~/}\";;"; print "  esac"; print "  # 4) $HOME/${HOME} в начале → абсолютный путь"; print "  case \"$p\" in"; print "    \"\$HOME\"/*)     p=\"$HOME/${p#\$HOME/}\";;"; print "    \"\${HOME}\"/*)   p=\"$HOME/${p#\${HOME}/}\";;"; print "    \"\$HOME\")       p=\"$HOME\";;"; print "    \"\${HOME}\")     p=\"$HOME\";;"; print "  esac"; print "  # 5) нормализация // (кроме схем)"; print "  echo \"$p\" | sed -E '\''s#(^|[^:])//+#\***REMOVED***/#g'\''"; next }
      infn && /^\}/ { print; infn=0; next }
      infn { next }
      { print }
    ' "$F" > "$F.tmp" && mv -f "$F.tmp" "$F"
    echo "[i] sanitizer body updated → $F"
  else
    awk 'NR==1{print; next}
         NR==2{
           print "set -Eeuo pipefail"
           print ""
           print "# --- WZ path sanitizer v2 ---"
           print "wz_sanitize_path(){"
           print "  local p=\"$1\""
           print "  # 1) срезать любые ведущие двоеточия"
           print "  while [ \"${p:0:1}\" = \":\" ]; do p=\"${p#:}\"; done"
           print "  # 2) убрать ведущие пробелы"
           print "  p=\"${p#${p%%[![:space:]]*}}\""
           print "  # 3) ~ → $HOME"
           print "  case \"$p\" in"
           print "    \"~\"|\"~/\") p=\"$HOME/\";;"
           print "    \"~\"/*)      p=\"$HOME/${p#~/}\";;"
           print "  esac"
           print "  # 4) $HOME/${HOME} в начале → абсолютный путь"
           print "  case \"$p\" in"
           print "    \"\$HOME\"/*)     p=\"$HOME/${p#\$HOME/}\";;"
           print "    \"\${HOME}\"/*)   p=\"$HOME/${p#\${HOME}/}\";;"
           print "    \"\$HOME\")       p=\"$HOME\";;"
           print "    \"\${HOME}\")     p=\"$HOME\";;"
           print "  esac"
           print "  # 5) нормализация // (кроме схем)"
           print "  echo \"$p\" | sed -E '\''s#(^|[^:])//+#\***REMOVED***/#g'\''"
           print "}"
           print "# --- /sanitizer ---"
           next
         }
         { print }' "$F" > "$F.tmp" && mv -f "$F.tmp" "$F"
    echo "[i] sanitizer inserted → $F"
  fi

  # 2) обёртка всех вхождений "$nested_file" → "$(wz_sanitize_path "$nested_file")" (идемпотентно)
  tmp="$(mktemp)"
  awk '
    {
      line=$0
      if (line ~ /wz_sanitize_path\(/) { print line; next }
      gsub(/\"\$nested_file\"/, "\"$(wz_sanitize_path \"$nested_file\")\"", line)
      print line
    }' "$F" > "$tmp" && mv -f "$tmp" "$F"
  echo "[i] wrap nested_file applied → $F"

  # 3) bash -n
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
  patch_file "$F"
done
