#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

WIKI1="$HOME/wz-wiki/scripts/wz_chatend.sh"
WIKI2="$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
LOG="$HOME/.wz_logs/fractal_chatend.log"
SAFELOG="$HOME/.wz_logs/wz_chatend_safe.log"
OUT="$HOME/.wz_tmp/wz_autofix_v2_1_report.txt"
TMPDIR="$(mktemp -d "${HOME}/.cache/tmp.XXXXXX" 2>/dev/null || mktemp -d)"

backup_file(){ [ -f "$1" ] && cp -f "$1" "$1.bak.$(date +%s)" && echo "[i] backup -> $1.bak.$(date +%s)"; }

# --- Блоки вставок (литералами) ---
mkdir -p "$TMPDIR"

cat > "$TMPDIR/sanitizer_v2.sh" <<'BLK'
# --- WZ path sanitizer v2 ---
wz_sanitize_path(){
  local p="$1"
  # снять ВСЕ ведущие двоеточия
  while [ "${p:0:1}" = ":" ]; do p="${p#:}"; done
  # убрать лидирующие пробелы
  p="${p#${p%%[![:space:]]*}}"
  case "$p" in
    "~"| "~/") p="$HOME/";;
    "~"/*)     p="$HOME/${p#~/}";;
  esac
  # нормализуем $HOME и ${HOME}
  case "$p" in
    "$HOME"/*)    p="$HOME/${p#$HOME/}";;
    "${HOME}"/*)  p="$HOME/${p#${HOME}/}";;
    "$HOME")      p="$HOME";;
    "${HOME}")    p="$HOME";;
  esac
  echo "$p" | sed -E 's#(^|[^:])//+#***REMOVED***/#g'
}
# --- /sanitizer ---
BLK

cat > "$TMPDIR/include_helper.sh" <<'BLK'
# --- Include extract helper ---
wz_extract_from_include(){
  # 1 arg: full line
  echo "$1" | sed -E 's/^Include:[[:space:]]*//'
}
# --- /Include extract ---
BLK

cat > "$TMPDIR/include_guard.sh" <<'BLK'
##__WZ_INCLUDE_GUARD__
if echo "$line" | grep -qiE '^Include:'; then
  nested_file="$(wz_extract_from_include "$line")"
fi
nested_file="$(wz_sanitize_path "$nested_file")"
BLK

insert_after_shebang(){
  local F="$1"; local BLOCK="$2"
  local TMP="$TMPDIR/after_shebang.tmp"
  head -n1 "$F" > "$TMP"
  cat "$BLOCK" >> "$TMP"
  tail -n +2 "$F" >> "$TMP"
  mv -f "$TMP" "$F"
}

# Вставка/замена sanitizer v2 (awk-safe: state/doneflag)
replace_or_insert_sanitizer_v2(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }

  if grep -q '^wz_sanitize_path()[[:space:]]*{' "$F"; then
    local TMP="$TMPDIR/rewrite_san.tmp"
    awk -v BLK="$TMPDIR/sanitizer_v2.sh" '
      BEGIN{ state=0; doneflag=0 }
      # начало старой функции
      /^wz_sanitize_path[[:space:]]*\(\)[[:space:]]*\{/ {
        state=1;
        print "# [wz] sanitizer v2 begin";
        # вставляем новый блок через system(cat ...)
        cmd="cat \"" BLK "\"";
        system(cmd);
        next;
      }
      # конец старой функции — закрывающая фигурная скобка на отдельной строке
      state==1 && /^\}[[:space:]]*$/ {
        state=0;
        print "# [wz] sanitizer v2 end";
        next;
      }
      # обычные строки, когда не внутри старой функции
      state==0 { print }
    ' "$F" > "$TMP"
    mv -f "$TMP" "$F"
    echo "[i] sanitizer v2 replaced: $F"
  else
    insert_after_shebang "$F" "$TMPDIR/sanitizer_v2.sh"
    echo "[i] sanitizer v2 inserted after shebang: $F"
  fi
}

ensure_include_helper(){
  local F="$1"
  [ -f "$F" ] || return 0
  if ! grep -q '^wz_extract_from_include()[[:space:]]*{' "$F"; then
    insert_after_shebang "$F" "$TMPDIR/include_helper.sh"
    echo "[i] include helper inserted: $F"
  else
    echo "[=] include helper exists: $F"
  fi
}

insert_guard_before_first_nested_use(){
  local F="$1"
  [ -f "$F" ] || return 0

  if grep -q '##__WZ_INCLUDE_GUARD__' "$F"; then
    echo "[=] include guard already present: $F"
    return 0
  fi

  local LN
  LN="$(grep -nE 'if[[:space:]]*\[[^]]*\$nested_file[^]]*\]' "$F" | head -n1 | cut -d: -f1 || true)"
  if [ -z "${LN:-}" ]; then
    LN="$(grep -n '\$nested_file' "$F" | head -n1 | cut -d: -f1 || true)"
  fi
  if [ -z "${LN:-}" ]; then
    echo "[WARN] no \$nested_file references in: $F"
    return 0
  fi

  local TMP="$TMPDIR/guard_ins.tmp"
  local PRE=$(( LN-1 ))
  [ "$PRE" -lt 1 ] && PRE=1
  sed -n "1,${PRE}p" "$F" > "$TMP"
  cat "$TMPDIR/include_guard.sh" >> "$TMP"
  sed -n "${LN},99999p" "$F" >> "$TMP"
  mv -f "$TMP" "$F"
  echo "[i] include guard inserted before line $LN: $F"
}

syntax_check(){ bash -n "$1" && echo "[OK] bash -n: $1" || { echo "[ERR] syntax: $1"; return 2; }; }

process_file(){
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }
  backup_file "$F"
  replace_or_insert_sanitizer_v2 "$F"
  ensure_include_helper "$F"
  insert_guard_before_first_nested_use "$F"
  syntax_check "$F"
}

# === Патчим обе копии ===
process_file "$WIKI1"
process_file "$WIKI2"

# === Чистый лог и тестовые входы ===
: > "$LOG" || true
mkdir -p "$HOME/wzbuffer/chatend_test"

cat > "$HOME/wzbuffer/chatend_test/nested.md" <<'MD'
# Nested
Content OK
MD

cat > "$HOME/wzbuffer/chatend_test/main.md" <<'MD'
# Main
Include: ~/wzbuffer/chatend_test/nested.md
MD

cat > "$HOME/wzbuffer/chatend_test/main_nospace.md" <<'MD'
# Main
Include:~/wzbuffer/chatend_test/nested.md
MD

# === Прогоны через safe-обёртку (без exec) ===
SAFE="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh"
if [ -x "$SAFE" ]; then
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main.md" || true
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main_nospace.md" || true
else
  echo "[WARN] safe wrapper not found: $SAFE"
fi

# === Сбор отчёта ===
SAFE_TAIL="$(tail -n 10 "$SAFELOG" 2>/dev/null || true)"
FRAC_TAIL="$(tail -n 120 "$LOG" 2>/dev/null || true)"
ANOM="$(printf "%s\n" "$FRAC_TAIL" | grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME' || true)"
NOFILE="$(printf "%s\n" "$FRAC_TAIL" | grep -n 'Не найден файл' || true)"

{
  echo "=== WZ ChatEnd Autofix v2.1 @$(date -u +%F' '%T)Z ==="
  echo "[safe.tail]"; printf "%s\n" "${SAFE_TAIL:-<none>}"
  echo "[anomalies]"; if [ -n "$ANOM" ]; then printf "%s\n" "$ANOM"; else echo "<none>"; fi
  echo "[nofile]";   if [ -n "$NOFILE" ]; then printf "%s\n" "$NOFILE"; else echo "<none>"; fi
} | tee "$OUT"

# В буфер
termux-clipboard-set < "$OUT" 2>/dev/null || true
echo "[i] report copied to clipboard: $OUT"
