#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:23+03:00-3342434645
# title: wz_chatend_md_proxy.sh
# component: .
# updated_at: 2025-08-26T13:19:23+03:00

# WZ ChatEnd MD Proxy v0.4 — Include-preprocess: expand ~ / $HOME (sed), colon-strip, TRACE raw/sane
set -Eeuo pipefail

SAFE_LOG="$HOME/.wz_logs/wz_chatend_safe.log"
FRAC_LOG="$HOME/.wz_logs/fractal_chatend.log"
TMP_DIR="$HOME/.wz_tmp"
mkdir -p "$(dirname "$SAFE_LOG")" "$(dirname "$FRAC_LOG")" "$TMP_DIR"

ts(){ date -u +'%Y-%m-%d %H:%M:%S'; }
slog(){ echo "[$(ts)] $*" >> "$SAFE_LOG"; }
flog(){ echo "[$(ts)] $*" >> "$FRAC_LOG"; }

wz_trim(){ sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//' -e 's/\r$//'; }

wz_expand_home(){
  # stdin/arg → stdout; strip leading ':', quotes; expand via sed; normalize //
  local p; p="$1"
  p="${p#:}"                 # strip leading ':'
  p="${p%\"}"; p="${p#\"}"   # strip double quotes
  p="${p%\'}"; p="${p#\'}"   # strip single quotes
  p="$(printf '%s' "$p" | wz_trim)"
  # жёсткая подстановка (без хитростей case/замены) — сначала $HOME, затем ~
  p="$(printf '%s' "$p" | sed -e "s#^\$HOME#$HOME#" -e "s#^~#$HOME#")"
  # нормализация // (не трогаем протоколы)
  printf '%s' "$p" | sed -E 's#(^|[^:])//+#***REMOVED***/#g'
}

preprocess_md(){
  local in="$1" out="$2"
  [ -f "$in" ] || { flog "⚠️ input missing: $in"; return 0; }
  flog "🌿 Препроцессинг: $in (depth=1)"
  : > "$out"

  local raw sane line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      Include:*)
        raw="${line#Include:}"
        raw="$(printf '%s' "$raw" | wz_trim)"
        sane="$(wz_expand_home "$raw")"
        flog "🔎 Include raw='$raw' sane='$sane'"
        if [ -f "$sane" ]; then
          flog "✅ Include OK: $raw → $sane"
          {
            echo "<!-- BEGIN Include: $raw → $sane -->"
            cat "$sane"
            echo "<!-- END Include: $sane -->"
          } >> "$out"
        else
          flog "⚠️ Не найден файл: $raw"
          echo "<!-- WARN: Include missing: $raw (expanded: $sane) -->" >> "$out"
        fi
        ;;
      *)
        printf '%s\n' "$line" >> "$out"
        ;;
    esac
  done < "$in"
}

# --- autodetect ORIG (wz-wiki) ---
: "${CHATEND_ORIG:=}"
if [ -z "${CHATEND_ORIG:-}" ]; then
  for C in "$HOME/wz-wiki/scripts/wz_chatend.sh" \
           "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
  do
    [ -x "$C" ] && CHATEND_ORIG="$C" && break
  done
fi
[ -n "${CHATEND_ORIG:-}" ] && [ -x "$CHATEND_ORIG" ] || {
  echo "[ERR] ORIG not found: ${CHATEND_ORIG:-unset}" >&2
  exit 2
}

# --- main ---
in_md="${1:-}"
[ -n "$in_md" ] || { echo "usage: $(basename "$0") path/to/input.md" >&2; exit 2; }
[ -f "$in_md" ] || { echo "[ERR] not a file: $in_md" >&2; exit 2; }

bn="$(basename "$in_md")"
pp="$TMP_DIR/pp_${bn%.*}_$EPOCHSECONDS.md"

preprocess_md "$in_md" "$pp"
slog "MD→ORIG: $in_md -> $pp"

# Делегируем в оригинал (он сам выведет "🔧 Markdown..." если без своей MD-генерации)
exec bash --norc "$CHATEND_ORIG" --md "$pp"
