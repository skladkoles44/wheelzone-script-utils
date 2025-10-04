#!/usr/bin/env bash
set -euo pipefail

TS="$(date -Iseconds)"
OUTDIR="${OUTDIR:-$HOME/wzbuffer/logs}"
LOG="$OUTDIR/git_sync_check_$(date +'%Y%m%d_%H%M%S').log"

# helper: clipboard mirror if available
clip() { command -v termux-clipboard-set >/dev/null && termux-clipboard-set; }

{
  echo "=== WheelZone Git comparison ( $TS ) ==="
  echo

  # wz-wiki
  echo "## wz-wiki"
  if cd "$HOME/wz-wiki" 2>/dev/null; then
    echo "PATH:    $(pwd)"
    git fetch --quiet origin || true
    BR="$(git rev-parse --abbrev-ref HEAD)"
    LCL="$(git rev-parse HEAD)"
    ORG="$(git rev-parse "origin/$BR" 2>/dev/null || echo 'n/a')"
    GIT="$(git ls-remote https://github.com/skladkoles44/wz-wiki.git HEAD 2>/dev/null | awk '{print $1}')" 
    echo "BRANCH:  $BR"
    echo "LOCAL:   $LCL"
    echo "ORIGIN:  $ORG   (origin/$BR)"
    echo "GITHUB:  $GIT    (ls-remote HEAD)"
  else
    echo "PATH:    not found"
  fi

  # VPS2 bare (через ssh)
  VPS_WIKI="unknown"
  if ssh -o ConnectTimeout=7 -p 2222 root@79.174.85.106 'git --git-dir=/root/git/wz-wiki.git rev-parse HEAD' >/dev/null 2>&1; then
    VPS_WIKI="$(ssh -o ConnectTimeout=7 -p 2222 root@79.174.85.106 'git --git-dir=/root/git/wz-wiki.git rev-parse HEAD' || echo unknown)"
  fi
  echo "VPS2:    $VPS_WIKI      (/root/git/wz-wiki.git)"
  echo "STATUS:  $( [[ "$LCL" = "$ORG" && "$ORG" = "${GIT:-x}" && "$GIT" = "$VPS_WIKI" ]] && echo '✅ In sync (LOCAL/ORIGIN/GITHUB/VPS2)' || echo '❌ Drift — различия есть' )"
  echo

  # wheelzone-script-utils
  echo "## wheelzone-script-utils"
  if cd "$HOME/wheelzone-script-utils" 2>/dev/null; then
    echo "PATH:    $(pwd)"
    git fetch --quiet origin || true
    BR="$(git rev-parse --abbrev-ref HEAD)"
    LCL="$(git rev-parse HEAD)"
    ORG="$(git rev-parse "origin/$BR" 2>/dev/null || echo 'n/a')"
    GIT="$(git ls-remote https://github.com/skladkoles44/wheelzone-script-utils.git HEAD 2>/dev/null | awk '{print $1}')"
    echo "BRANCH:  $BR"
    echo "LOCAL:   $LCL"
    echo "ORIGIN:  $ORG   (origin/$BR)"
    echo "GITHUB:  $GIT    (ls-remote HEAD)"
  else
    echo "PATH:    not found"
  fi

  VPS_UTILS="unknown"
  if ssh -o ConnectTimeout=7 -p 2222 root@79.174.85.106 'git --git-dir=/root/git/wheelzone-script-utils.git rev-parse HEAD' >/dev/null 2>&1; then
    VPS_UTILS="$(ssh -o ConnectTimeout=7 -p 2222 root@79.174.85.106 'git --git-dir=/root/git/wheelzone-script-utils.git rev-parse HEAD' || echo unknown)"
  fi
  echo "VPS2:    $VPS_UTILS      (/root/git/wheelzone-script-utils.git)"
  echo "STATUS:  $( [[ "$LCL" = "$ORG" && "$ORG" = "${GIT:-x}" && "$GIT" = "$VPS_UTILS" ]] && echo '✅ In sync (LOCAL/ORIGIN/GITHUB/VPS2)' || echo '❌ Drift — различия есть' )"

  echo
  echo "=== Legend ==="
  echo "• ✅ In sync — всё совпадает.  • ❌ Drift — есть различия."
} | tee "$LOG" | clip

# 2) апдейтим историю в wz-wiki и пушим (только если файл изменился)
cd "$HOME/wz-wiki"
mkdir -p docs/ops
HIS="docs/ops/git-sync-history.md"

# гарантируем фронт-маттер с fractal_uuid
if ! head -n 3 "$HIS" 2>/dev/null | grep -q '^---$'; then
  {
    echo '---'
    echo "fractal_uuid: $(uuidgen)"
    echo '---'
    echo
  } | cat - "$HIS" 2>/dev/null > "$HIS.tmp" && mv "$HIS.tmp" "$HIS"
fi

{
  echo "## Срез: $TS"
  echo
  sed -n '1,200p' "$LOG"
  echo
} >> "$HIS"

git add "$HIS" || true

if ! git diff --cached --quiet; then
  # локальный pre-commit у тебя уже чинит fractal_uuid при необходимости
  git commit -m "ops: record Git sync status $TS" || true
  git push || true
fi

echo "[saved] $HIS"
echo "[log saved] $LOG"
