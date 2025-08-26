#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:41+03:00-357313187
# title: wz_chatend_autofix_run.sh
# component: .
# updated_at: 2025-08-26T13:19:42+03:00

set -Eeuo pipefail

WIKI1="$HOME/wz-wiki/scripts/wz_chatend.sh"
WIKI2="$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
LOG="$HOME/.wz_logs/fractal_chatend.log"
SAFELOG="$HOME/.wz_logs/wz_chatend_safe.log"
OUT="/tmp/wz_autofix_report_$$.txt"

backup_file(){ [ -f "$1" ] && cp -f "$1" "$1.bak.$(date +%s)" && echo "[i] backup: $1.bak.$(date +%s)"; }

ensure_sanitizer_v2(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }
  if ! grep -q 'wz_sanitize_path()' "$F"; then
    awk 'NR==1{print; next}
         NR==2{
           print "set -Eeuo pipefail"
           print ""
           print "# --- WZ path sanitizer v2 ---"
           print "wz_sanitize_path(){"
           print "  local p=\"$1\""
           print "  while [ \"${p:0:1}\" = \":\" ]; do p=\"${p#:}\"; done"
           print "  p=\"${p#${p%%[![:space:]]*}}\""
           print "  case \"$p\" in"
           print "    \"~\"|\"~/\") p=\"$HOME/\";;"
           print "    \"~\"/*)      p=\"$HOME/${p#~/}\";;"
           print "  esac"
           print "  case \"$p\" in"
           print "    \"\$HOME\"/*)     p=\"$HOME/${p#\$HOME/}\";;"
           print "    \"\${HOME}\"/*)   p=\"$HOME/${p#\${HOME}/}\";;"
           print "    \"\$HOME\")       p=\"$HOME\";;"
           print "    \"\${HOME}\")     p=\"$HOME\";;"
           print "  esac"
           print "  echo \"$p\" | sed -E '\''s#(^|[^:])//+#\***REMOVED***/#g'\''"
           print "}"
           print "# --- /sanitizer ---"
           next
         }
         { print }' "$F" > "$F.tmp0" && mv -f "$F.tmp0" "$F"
    echo "[i] sanitizer v2 inserted: $F"
  else
    # усилим удаление ':' если нет цикла while
    if ! grep -q 'while \[ "\$\{p:0:1\}" = ":" \]' "$F"; then
      awk '
        BEGIN{done=0}
        {
          if (!done && $0 ~ /wz_sanitize_path\(\)\{/){
            print
            print "  local p=\"$1\""
            print "  while [ \"${p:0:1}\" = \":\" ]; do p=\"${p#:}\"; done"
            next
          }
          if ($0 ~ /local p=/) { next }
          print
        }' "$F" > "$F.tmpw" && mv -f "$F.tmpw" "$F"
      echo "[i] sanitizer v2 upgraded (colon-strip): $F"
    else
      echo "[=] sanitizer v2 already present: $F"
    fi
  fi
}

inject_include_extract_guard(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }

  # Вставим guard ПЕРЕД первой проверкой if [...] $nested_file ...
  # Вставляем ТОЛЬКО если ещё не вставлен.
  if ! grep -q 'wz_extract_from_include' "$F"; then
    # 1) вставим helper для извлечения
    awk 'NR==1{print; next}
         NR==2{
           print "set -Eeuo pipefail"
           print ""
           print "# --- Include extract helper ---"
           print "wz_extract_from_include(){"
           print "  # 1 arg: full line"
           print "  echo \"$1\" | sed -E '\''s/^Include:[[:space:]]*//'\''"
           print "}"
           print "# --- /Include extract ---"
           next
         }
         { print }' "$F" > "$F.tmpE" && mv -f "$F.tmpE" "$F"
    echo "[i] extract helper inserted: $F"
  fi

  # 2) добавим блок до первой проверки if [ ... $nested_file ... ]
  if ! grep -q '##__WZ_INCLUDE_GUARD__' "$F"; then
    awk '
      BEGIN{ins=0}
      {
        if (!ins && $0 ~ /if[[:space:]]*\[[^]]*\$nested_file[^]]*\]/) {
          print "##__WZ_INCLUDE_GUARD__"
          print "if echo \"$line\" | grep -qiE '\''^Include:'\''; then"
          print "  nested_file=\"$(wz_extract_from_include \"$line\")\""
          print "fi"
          print "nested_file=\"$(wz_sanitize_path \"$nested_file\")\""
          ins=1
        }
        print
      }' "$F" > "$F.tmpG" && mv -f "$F.tmpG" "$F"
    echo "[i] include-guard injected before first if [...] $nested_file: $F"
  else
    echo "[=] include-guard already exists: $F"
  fi
}

wrap_all_nested_usages(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }

  awk '
    {
      line=$0
      # пропускаем присваивание nested_file=...
      if (line ~ /^[[:space:]]*nested_file[[:space:]]*=/) { print line; next }

      gsub(/-f[[:space:]]+\$nested_file\b/, "-f \"$(wz_sanitize_path \\\"$nested_file\\\")\"", line)
      gsub(/-r[[:space:]]+\$nested_file\b/, "-r \"$(wz_sanitize_path \\\"$nested_file\\\")\"", line)

      gsub(/\"\$nested_file\"/, "\"$(wz_sanitize_path \\\"$nested_file\\\")\"", line)
      gsub(/\"\$nested_file\b/, "\"$(wz_sanitize_path \\\"$nested_file\\\")", line)

      gsub(/\$nested_file\b/, "\"$(wz_sanitize_path \\\"$nested_file\\\")\"", line)

      # лог "Не найден файл" — тоже через sanitizer
      sub(/flog[[:space:]]*\"⚠️ Не найден файл:.*\)/,
          "flog \"⚠️ Не найден файл: $(wz_sanitize_path \\\"$nested_file\\\")\")", line)

      print line
    }' "$F" > "$F.tmpW" && mv -f "$F.tmpW" "$F"
  echo "[i] nested_file usages wrapped: $F"
}

syntax_check(){ bash -n "$1" && echo "[OK] bash -n: $1" || { echo "[ERR] syntax: $1"; return 2; }; }

process_file(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }
  backup_file "$F"
  ensure_sanitizer_v2 "$F"
  inject_include_extract_guard "$F"
  wrap_all_nested_usages "$F"
  syntax_check "$F"
}

# === 1) Патчим обе копии (если есть) ===
process_file "$WIKI1"
process_file "$WIKI2"

# === 2) Очистка лога (чистый эксперимент) ===
: > "$LOG" || true

# === 3) Готовим тестовые файлы ===
mkdir -p "$HOME/wzbuffer/chatend_test"
cat > "$HOME/wzbuffer/chatend_test/main.md" <<'MD'
# Main
Include: ~/wzbuffer/chatend_test/nested.md
MD

cat > "$HOME/wzbuffer/chatend_test/main_nospace.md" <<'MD'
# Main
Include:~/wzbuffer/chatend_test/nested.md
MD

cat > "$HOME/wzbuffer/chatend_test/nested.md" <<'MD'
# Nested
Content OK
MD

# === 4) Два прогона (без exec) через safe-обёртку ===
SAFE="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh"
if [ -x "$SAFE" ]; then
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main.md" || true
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main_nospace.md" || true
else
  echo "[WARN] safe wrapper not found: $SAFE"
fi

# === 5) Скан последних сообщений ===
SAFE_TAIL="$(tail -n 8 "$SAFELOG" 2>/dev/null || true)"
FRAC_TAIL="$(tail -n 120 "$LOG" 2>/dev/null || true)"
ANOM="$(printf "%s\n" "$FRAC_TAIL" | grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME' || true)"
NOFILE="$(printf "%s\n" "$FRAC_TAIL" | grep -n 'Не найден файл' || true)"

# === 6) Контроль тестовых путей (nested_test.md) ===
CHK_NESTED_TEST=""
[ -f "$HOME/wzbuffer/nested_test.md" ] || CHK_NESTED_TEST="absent: $HOME/wzbuffer/nested_test.md"

# === 7) Отчёт ===
{
  echo "=== WZ ChatEnd Autofix @$(date -u +%F' '%T)Z ==="
  echo "[safe.tail]"; printf "%s\n" "${SAFE_TAIL:-<none>}"
  echo "[anomalies]"; if [ -n "$ANOM" ]; then printf "%s\n" "$ANOM"; else echo "<none>"; fi
  echo "[nofile]";   if [ -n "$NOFILE" ]; then printf "%s\n" "$NOFILE"; else echo "<none>"; fi
  echo "[check] $CHK_NESTED_TEST"
} | tee "$OUT"

# Копируем краткий отчёт в буфер
termux-clipboard-set < "$OUT" 2>/dev/null || true
echo "[i] report copied to clipboard: $OUT"
