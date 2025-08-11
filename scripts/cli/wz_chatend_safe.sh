# --- WZ auto-detect CHATEND_ORIG ---
: "${CHATEND_ORIG:=}"
if [ -z "${CHATEND_ORIG}" ]; then
  for C in "$HOME/wz-wiki/scripts/wz_chatend.sh" \
           "$HOME/wz-wiki/wz-wiki/scripts/wz_chatend.sh" \
           "$HOME/wheelzone-script-utils/scripts/cli/wz_chatend.sh"
  do
    [ -x "$C" ] && CHATEND_ORIG="$C" && break
  done
fi
if [ -z "${CHATEND_ORIG:-}" ] || [ ! -x "$CHATEND_ORIG" ]; then
  echo "[ERR] CHATEND_ORIG not found or not executable: ${CHATEND_ORIG:-unset}" >&2
  exit 2
fi
# --- /auto-detect ---
