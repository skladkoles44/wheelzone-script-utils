#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:22+03:00-3062121464
# title: wz_chatend.sh
# component: .
# updated_at: 2025-08-26T13:19:22+03:00

# WZ ChatEnd CLI Proxy v0.1 — делегирует вызов в оригинал wz-wiki/scripts/wz_chatend.sh
set -Euo pipefail

SAFE_LOG="$HOME/.wz_logs/wz_chatend_safe.log"
mkdir -p "$(dirname "$SAFE_LOG")"

: "${CHATEND_ORIG:=}"
# Автодетект, если не передали через окружение
if [ -z "${CHATEND_ORIG:-}" ]; then
  for C in "$HOME/wz-wiki/scripts/wz_chatend.sh" \
           "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh"
  do
    if [ -x "$C" ]; then CHATEND_ORIG="$C"; break; fi
  done
fi

if [ -z "${CHATEND_ORIG:-}" ] || [ ! -x "$CHATEND_ORIG" ]; then
  echo "[ERR] ORIG not found: ${CHATEND_ORIG:-unset}" >&2
  exit 2
fi

echo "[$(date -u +'%F %T')] PROXY→ $CHATEND_ORIG args=[$*]" >> "$SAFE_LOG"
exec bash --norc "$CHATEND_ORIG" "$@"
