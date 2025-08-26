#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:43+03:00-2639721520
# title: wz_md_preprocess_includes.sh
# component: .
# updated_at: 2025-08-26T13:19:43+03:00

# wz_md_preprocess_includes.sh v1.0
# Usage: wz_md_preprocess_includes.sh INPUT_MD OUTPUT_MD
# Безопасный препроцессинг Markdown: разворачивает строки "Include: <path>",
# поддерживает "~", "$HOME", "Include:~/...", "Include: $HOME/...", с защитой от циклов.

set -Eeuo pipefail

FRAC_LOG="$HOME/.wz_logs/fractal_chatend.log"
mkdir -p "$(dirname "$FRAC_LOG")"

ts(){ date -u +'%Y-%m-%d %H:%M:%S'; }
log(){ echo "[$(ts)] $*" >> "$FRAC_LOG"; }

trim(){
  sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//' -e 's/\r$//'
}

expand_home(){
  # $1: raw path → echo sane
  local p="$1"
  p="${p#:}"                 # strip leading ':'
  p="${p%\"}"; p="${p#\"}"   # strip "
  p="${p%\'}"; p="${p#\'}"   # strip '
  p="$(printf '%s' "$p" | trim)"
  case "$p" in
    \$HOME|\$HOME/*) p="${p/#\$HOME/$HOME}";;
    ~|~/*)           p="${p/#~/$HOME}";;
  esac
  # normalize double slashes (except protocol)
  printf '%s' "$p" | sed -E 's#(^|[^:])//+#***REMOVED***/#g'
}

# Глобальная защита от глубины
: "${WZ_INCLUDE_MAX_DEPTH:=5}"

# render_file IN_MD OUT_MD DEPTH
render_file(){
  local in="$1" out="$2" depth="$3"
  if [ "$depth" -gt "${WZ_INCLUDE_MAX_DEPTH}" ]; then
    log "⚠️ max-depth exceeded at: $in"
    return 0
  fi
  [ -f "$in" ] || { log "⚠️ input missing: $in"; return 0; }

  echo "[${PPID}_${RANDOM}] ↳ 🌿 Препроцессинг: $in (depth=$depth)" >> "$FRAC_LOG"

  : > "$out"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      Include:*)
        raw="${line#Include:}"
        raw="$(printf '%s' "$raw" | trim)"
        # аномалии в сыром виде (историческая проверка)
        if printf '%s\n' "$raw" | grep -Eq '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME'; then
          echo "[${PPID}_${RANDOM}] ↳ ⚠️ Не найден файл: $raw" >> "$FRAC_LOG"
          printf '%s\n' "<!-- WARN: Include unresolved (raw anomaly): $raw -->" >> "$out"
          continue
        fi
        sane="$(expand_home "$raw")"
        if [ -f "$sane" ]; then
          echo "[${PPID}_${RANDOM}] ↳ ✅ Include OK: $raw → $sane" >> "$FRAC_LOG"
          printf '%s\n' "<!-- BEGIN Include: $raw → $sane -->" >> "$out"
          # рекурсивный рендер
          tmp="$(mktemp "${HOME}/.wz_tmp/pp.${depth}.XXXXXX")"
          render_file "$sane" "$tmp" "$((depth+1))"
          cat "$tmp" >> "$out"
          rm -f "$tmp"
          printf '%s\n' "<!-- END Include: $sane -->" >> "$out"
        else
          echo "[${PPID}_${RANDOM}] ↳ ⚠️ Не найден файл: $raw" >> "$FRAC_LOG"
          printf '%s\n' "<!-- WARN: Include missing: $raw (expanded: $sane) -->" >> "$out"
        fi
        ;;
      *)
        printf '%s\n' "$line" >> "$out"
        ;;
    esac
  done < "$in"
}

main(){
  [ $# -ge 2 ] || { echo "Usage: $0 INPUT_MD OUTPUT_MD" >&2; exit 2; }
  local in="$1" out="$2"
  render_file "$in" "$out" 1
}
main "$@"
