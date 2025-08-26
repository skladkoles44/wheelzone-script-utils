#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:23+03:00-2679168039
# title: wz_chatend_md.sh
# component: .
# updated_at: 2025-08-26T13:19:23+03:00

# WZ ChatEnd MD Proxy v0.2 — preprocess Include, затем вызвать ORIG с --md
set -Eeuo pipefail
FRAC_LOG="$HOME/.wz_logs/fractal_chatend.log"
SAFE_LOG="$HOME/.wz_logs/wz_chatend_safe.log"
PP="$HOME/wheelzone-script-utils/scripts/utils/wz_md_preprocess_includes.sh"
mkdir -p "$(dirname "$FRAC_LOG")" "$(dirname "$SAFE_LOG")" "$HOME/.wz_tmp"

ts(){ date -u +'%Y-%m-%d %H:%M:%S'; }
slog(){ echo "[$(ts)] $*" >> "$SAFE_LOG"; }

# Автодетект ORIG (локальный wz-wiki)
: "${CHATEND_ORIG:=}"
if [ -z "${CHATEND_ORIG:-}" ]; then
  for C in "$HOME/wz-wiki/scripts/wz_chatend.sh" "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"; do
    [ -x "$C" ] && CHATEND_ORIG="$C" && break
  done
fi
[ -x "${CHATEND_ORIG:-}" ] || { echo "[ERR] ORIG not found: ${CHATEND_ORIG:-unset}" >&2; exit 2; }
[ -x "$PP" ] || { echo "[ERR] preprocessor missing: $PP" >&2; exit 2; }

# Обработка входных MD
status=0
for in_md in "$@"; do
  if [ ! -f "$in_md" ]; then
    slog "SKIP missing: $in_md"
    continue
  fi
  base="$(basename "$in_md")"
  out_md="$HOME/.wz_tmp/pp_${base%.*}_$(date +%s).md"
  # preprocess
  "$PP" "$in_md" "$out_md" || true
  slog "MD→ORIG: $in_md -> $out_md"
  # вызов ORIG с --md (ориг может не рендерить — это ок, нам важен preprocess)
  bash --norc "$CHATEND_ORIG" --md "$out_md" || status=$?
done

exit "$status"
