#!/data/data/com.termux/files/usr/bin/bash
# Ensure logs/ai is not ignored by Git
grep -q "!logs/ai/" "$HOME/wz-wiki/.gitignore" || echo "!logs/ai/" >> "$HOME/wz-wiki/.gitignore"
# wz_ai_capture.sh — Захват вывода команды в AI-буфер
set -euo pipefail

logdir="$HOME/.wz_logs/ai"
mkdir -p "$logdir"
uuid=$(uuidgen | tr 'A-Z' 'a-z')
ts=$(date -Iseconds)
label="${1:-capture}"
shift || true

tmpout="$(mktemp)"
tmperr="$(mktemp)"

{
  "$@" >"$tmpout" 2>"$tmperr"
} || true

out=$(<"$tmpout")
err=$(<"$tmperr")

rm -f "$tmpout" "$tmperr"

cat >> "$logdir/ai_log_$(date +%Y%m%d).ndjson" <<EOF2
{"uuid":"$uuid","time":"$ts","type":"capture","label":"$label","stdout":$(jq -Rs . <<<"$out"),"stderr":$(jq -Rs . <<<"$err")}
EOF2

echo "[✓] Захват выполнен: $label → $uuid"

# ⬇ Автокоммит
bash ~/wheelzone-script-utils/scripts/autocommit/wz_autocommit.sh "AutoCommit from wz_ai_capture.sh"
