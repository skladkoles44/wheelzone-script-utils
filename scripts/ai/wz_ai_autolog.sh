#!/data/data/com.termux/files/usr/bin/bash
# Ensure logs/ai is not ignored by Git
grep -q "!logs/ai/" "$HOME/wz-wiki/.gitignore" || echo "!logs/ai/" >> "$HOME/wz-wiki/.gitignore"
# wz_ai_autolog.sh — Захват + git push + GDrive автосинхронизация
set -euo pipefail

label="${1:-autolog}"
shift || true
cmd="$*"

logdir="$HOME/.wz_logs/ai"
mkdir -p "$logdir"
uuid=$(uuidgen | tr 'A-Z' 'a-z')
ts=$(date -Iseconds)

tmpout="$(mktemp)"
tmperr="$(mktemp)"

{
  eval "$cmd" >"$tmpout" 2>"$tmperr"
} || true

out=$(<"$tmpout")
err=$(<"$tmperr")
rm -f "$tmpout" "$tmperr"

logfile="$logdir/ai_log_$(date +%Y%m%d).ndjson"
cat >> "$logfile" <<EOF2
{"uuid":"$uuid","time":"$ts","type":"autolog","label":"$label","stdout":$(jq -Rs . <<<"$out"),"stderr":$(jq -Rs . <<<"$err")}
EOF2

echo "[✓] Автозахват: $label → $uuid"

# Git-синхронизация
dst_git="$HOME/wz-wiki/logs/ai"
mkdir -p "$dst_git"
cp "$logfile" "$dst_git" || true
cd "$dst_git"
git add *.ndjson
git commit -m "[AI-Autolog] $label → $uuid" || true
git push || echo "[!] Git push пропущен"

# GDrive
if rclone listremotes 2>/dev/null | grep -q gdrive:; then
  rclone copy "$logdir" gdrive:wz-logs/ai/ --update
fi

# ⬇ Автокоммит
bash ~/wheelzone-script-utils/scripts/autocommit/wz_autocommit.sh "AutoCommit from wz_ai_autolog.sh"
