#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:38+03:00-3784523884
# title: patch_cli_wz_chatend_arg_guard.sh
# component: .
# updated_at: 2025-08-26T13:19:38+03:00

set -Eeuo pipefail
F="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend.sh"
[ -f "$F" ] || { echo "[skip] no file: $F"; exit 0; }

BAK="$F.bak.$(date +%s)"
cp -f "$F" "$BAK"
echo "[i] backup: $BAK"

# Вставить после первой строки set -Eeuo pipefail блок, создающий пустой $2 если его нет
awk '
  BEGIN{ins=0}
  {
    print
    if (!ins && $0 ~ /^set -E.*pipefail/) {
      print ""
      print "# --- arg guard: ensure $2 exists ---"
      print "if [ $# -lt 2 ]; then set -- \"$@\" \"\"; fi"
      print "# --- /arg guard ---"
      ins=1
    }
  }' "$F" > "$F.tmp" && mv -f "$F.tmp" "$F"

if bash -n "$F"; then
  echo "[OK] bash -n: $F"
else
  echo "[ERR] syntax: restore $BAK"
  cp -f "$BAK" "$F"
  exit 2
fi
