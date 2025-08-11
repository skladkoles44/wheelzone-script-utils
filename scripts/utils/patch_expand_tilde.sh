#!/data/data/com.termux/files/usr/bin/bash
# patch_expand_tilde.sh v1.0 — добавляет wz_expand_home() и применяет к $nested_file
set -Eeuo pipefail

patch_one() {
  local F="$1"
  [ -f "$F" ] || { echo "[skip] no file: $F"; return 0; }

  local BAK="$F.bak.$(date +%s)"
  cp -f "$F" "$BAK"
  echo "[i] backup: $BAK"

  local TMPDIR; TMPDIR="$(mktemp -d "${HOME}/.cache/patch_tilde.XXXXXX" 2>/dev/null || mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  # helper-блок
  local HELPER="$TMPDIR/helper.sh"
  cat > "$HELPER" <<'BLK'
# --- WZ expand helper ---
wz_trim(){ sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//' -e 's/\r$//'; }
wz_expand_home(){
  local p; p="$1"
  p="${p#:}"                 # убрать ведущий ':'
  p="${p%\"}"; p="${p#\"}"   # снять "
  p="${p%\'}"; p="${p#\'}"   # снять '
  p="$(printf '%s' "$p" | wz_trim)"
  case "$p" in
    \$HOME|\$HOME/*) p="${p/#\$HOME/$HOME}";;
    ~|~/*)           p="${p/#~/$HOME}";;
  esac
  printf '%s' "$p" | sed -E 's#(^|[^:])//+#***REMOVED***/#g'
}
# --- /WZ expand helper ---
BLK

  # 1) Вставить helper, если его нет
  if ! grep -qE '^(wz_expand_home|wz_trim)\(\)[[:space:]]*\{' "$F"; then
    awk -v BLK="$HELPER" '
      NR==1{print; next}
      NR==2{system("cat " BLK); print; next}
      {print}
    ' "$F" > "$F.tmp1"
    mv -f "$F.tmp1" "$F"
    chmod +x "$F"
    echo "[i] helper inserted → $F"
  else
    echo "[=] helper already present in $F"
  fi

  # 2) Перед первой проверкой if [...] $nested_file — применить expand (если ещё не применён)
  if ! grep -q 'wz_expand_home "$nested_file"' "$F"; then
    awk '
      BEGIN{ins=0}
      {
        if(!ins && $0 ~ /if[[:space:]]*\[[^]]*\$nested_file[^]]*\]/){
          print "nested_file=\"$(wz_expand_home \"$nested_file\")\""
          ins=1
        }
        print
      }
    ' "$F" > "$F.tmp2"
    mv -f "$F.tmp2" "$F"
    chmod +x "$F"
    echo "[i] expand call inserted → $F"
  else
    echo "[=] expand already present in $F"
  fi

  # 3) Синтакс-проверка
  if bash -n "$F"; then
    echo "[OK] bash -n passed: $F"
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
