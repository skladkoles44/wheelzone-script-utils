#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:05+03:00-2664297038
# title: wz_history_check.sh
# component: .
# updated_at: 2025-08-26T13:19:05+03:00

# WZ History Healthcheck v3-mini
set -Eeuo pipefail
CORE="$HOME/wheelzone-script-utils/cron/wz_history_core.sh"
SRC="${SRC_DIR:-$HOME/.wz_history}"
LOG="$HOME/.wz_backup.log"
DO_SHARE=0; DO_BACKUP=0; DO_FIX_IDX=0; DO_FIX_HDR=0
for a in "$@"; do
  case "$a" in
    --share-test) DO_SHARE=1 ;;
    --backup-test) DO_BACKUP=1 ;;
    --fix-index) DO_FIX_IDX=1 ;;
    --fix-headers-test) DO_FIX_HDR=1 ;;
  esac
done
ok(){ printf "✅ %s\n" "$*"; }
warn(){ printf "⚠️ %s\n" "$*"; }
err(){ printf "❌ %s\n" "$*"; exit 1; }
sec(){ printf "\n——— %s ———\n" "$*"; }

sec "Core"
[ -x "$CORE" ] && ok "found: $CORE" || err "missing core"

sec "History dir"
[ -d "$SRC" ] && ok "dir: $SRC" || err "missing dir: $SRC"
printf "   files(md/json): %s\n" "$(find "$SRC" -maxdepth 1 -type f \( -name '*.md' -o -name '*.json' \) | wc -l | tr -d ' ')"
ls -1t "$SRC" | head -n5 | sed 's/^/   • /' || true

sec "Latest MD header"
last="$(ls -1t "$SRC"/*.md 2>/dev/null | head -n1 || true)"
[ -z "$last" ] && { warn "no .md files"; exit 0; }
echo "   file: $(basename "$last")"
awk 'BEGIN{h=0} /^---$/{h++;next} h==1{print}' "$last" | sed 's/^/   /'
[ $DO_FIX_HDR -eq 1 ] && bash "$HOME/wheelzone-script-utils/scripts/utils/wz_history_fix_headers.sh" || true

sec "index.json"
IDX="$SRC/index.json"
if python3 - <<PY 2>/dev/null
import json,sys; import pathlib
p=pathlib.Path("$IDX")
json.load(p.open()) if p.exists() else None
print("OK")
PY
then
  ok "index.json ok"; head -n10 "$IDX" | sed 's/^/   /' || true
else
  if [ $DO_FIX_IDX -eq 1 ]; then
    python3 - "$SRC" <<'PY'
import os,sys,json,time
src=sys.argv[1]; data=[]
for f in sorted(os.listdir(src)):
    if not f.endswith(".md"): continue
    p=os.path.join(src,f)
    try:
        msgs=sum(1 for l in open(p,'r',errors='ignore') if l.strip()=="---")
        ts=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(os.path.getmtime(p)))
        data.append({"file":f,"last_update":ts,"messages":msgs})
    except Exception: pass
json.dump(data, open(os.path.join(src,"index.json"),"w"), ensure_ascii=False, indent=2)
print("rebuilt")
PY
    ok "index rebuilt"
  else
    warn "index invalid/absent"
  fi
fi

sec "Backup"
if command -v rclone >/dev/null 2>&1; then
  ok "rclone installed"
  [ -f "$LOG" ] && tail -n3 "$LOG" | sed 's/^/   /' || warn "no backup log"
  [ $DO_BACKUP -eq 1 ] && bash "$HOME/wheelzone-script-utils/cron/wz_history_backup.sh" && tail -n3 "$LOG" | sed 's/^/   /' || true
else
  warn "rclone missing"
fi

sec "URL opener"
if command -v termux-url-opener >/dev/null 2>&1; then
  ok "opener installed"; which termux-url-opener | sed 's/^/   /'
  [ $DO_SHARE -eq 1 ] && "$HOME/bin/termux-url-opener" "https://chat.openai.com/share/test-$(date +%s)" || true
else
  warn "opener missing"
fi

sec "Scheduler"
termux-job-scheduler --list 2>/dev/null | sed 's/^/   /' || warn "scheduler unavailable"

printf "\n— Done. Flags: --share-test --backup-test --fix-index --fix-headers-test\n"
