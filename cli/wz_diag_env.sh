#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# WZ Diagnostics — Termux + VPS
# -------------------------------
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="/sdcard/Download/Logs"
YAML="$OUT_DIR/wz_diag_${TS}.yaml"
MD="$OUT_DIR/wz_diag_${TS}.md"
mkdir -p "$OUT_DIR"

# Цели
SSH_HOST="${SSH_HOST:-79.174.85.106}"
SSH_PORT="${SSH_PORT:-2222}"

LOCAL_REPOS=(
  "$HOME/wz-wiki"
  "$HOME/wheelzone-script-utils"
  "$HOME/wheelzone-opt-api"
)

REMOTE_BARE_REPOS=(
  "/root/git/wz-wiki.git"
  "/root/git/wheelzone-script-utils.git"
  "/root/git/wheelzone-opt-api.git"
)

SECRETS_FILES=(
  "$HOME/.wz_api_token"
  "$HOME/.env.wzbot"
  "$HOME/.env.notion"
  "$HOME/wheelzone-script-utils/configs/.env.notion"
)

_mask() {
  local s="$1"; local n="${#s}"
  if (( n <= 8 )); then printf "%s" "****"
  else printf "%s****%s" "${s:0:4}" "${s: -4}"
  fi
}

_cmd_v() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    "$name" --version 2>/dev/null | head -n1 || "$name" version 2>/dev/null | head -n1 || echo "OK"
  else
    echo "MISSING"
  fi
}

_git_remote_ok() {
  local path="$1"
  local need="root@${SSH_HOST}:${SSH_PORT}"
  git -C "$path" remote -v 2>/dev/null | grep -q "$need" && echo "OK" || echo "CHECK"
}

_try_ssh() {
  ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=5 root@"$SSH_HOST" 'echo OK' 2>/dev/null || true
}

TERMUX_INFO="$(uname -a 2>/dev/null || true)"
ANDROID_SDK="$(getprop ro.build.version.release 2>/dev/null || true)"
GO_V="$(_cmd_v go)"; GIT_V="$(_cmd_v git)"; SSH_V="$(_cmd_v ssh)"
PY_V="$(_cmd_v python3)"; PIP_V="$(_cmd_v pip)"
PSQL_V="$(_cmd_v psql)"; SQLC_V="$(_cmd_v sqlc)"; DOCKER_V="$(_cmd_v docker)"
SSH_OK="$(_try_ssh)"

LOCAL_REPO_REPORT=""
for r in "${LOCAL_REPOS[@]}"; do
  if [ -d "$r/.git" ]; then
    branch="$(git -C "$r" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")"
    remote_check="$(_git_remote_ok "$r")"
    status="$(git -C "$r" status --porcelain -b 2>/dev/null | head -n1 || echo "")"
    LOCAL_REPO_REPORT+=$(printf -- "- path: %s\n  exists: true\n  branch: %s\n  remote: %s\n  head: %s\n" \
      "$r" "$branch" "$remote_check" "$status")
  else
    LOCAL_REPO_REPORT+=$(printf -- "- path: %s\n  exists: false\n" "$r")
  fi
done

SECRETS_REPORT=""
for f in "${SECRETS_FILES[@]}"; do
  if [ -f "$f" ]; then
    first="$(head -c 24 "$f" 2>/dev/null | tr -d '\n' || true)"
    line="$(grep -m1 -E '(^[A-Z0-9_]+ *= *[^#].*)' "$f" 2>/dev/null | head -n1 || true)"
    masked="$(_mask "${first:-OK}")"
    SECRETS_REPORT+=$(printf -- "- path: %s\n  exists: true\n  preview: %s\n  first_env_line: %s\n" "$f" "$masked" "${line//:/ }")
  else
    SECRETS_REPORT+=$(printf -- "- path: %s\n  exists: false\n" "$f")
  fi
done

REMOTE_REPORT="$(ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=7 root@"$SSH_HOST" bash -s <<'EOSH'
set -euo pipefail
host="$(hostname)"
os="$(uname -a || true)"
ports="$(ss -ltnp 2>/dev/null | awk 'NR==1 || /:22 |:2222 /')"
git_v="$(git --version 2>/dev/null || echo MISSING)"

check_repo() {
  local path="$1"
  if [ -d "$path" ]; then
    cd "$path"
    headref="$(git symbolic-ref HEAD 2>/dev/null || echo unknown)"
    echo "- path: $path"
    echo "  exists: true"
    echo "  headref: $headref"
  else
    echo "- path: $path"
    echo "  exists: false"
  fi
}

echo "host: $host"
echo "os: $os"
echo "ssh_listen:"
echo "$ports" | sed 's/^/  /'
echo "git: $git_v"
echo "bare_repos:"
EOSH
)"

for repo in "${REMOTE_BARE_REPOS[@]}"; do
  REMOTE_REPORT+="$(
    ssh -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=7 root@"$SSH_HOST" bash -s <<EOSH
check_repo() {
  local path="\$1"
  if [ -d "\$path" ]; then
    cd "\$path"
    headref="\$(git symbolic-ref HEAD 2>/dev/null || echo unknown)"
    echo "- path: \$path"
    echo "  exists: true"
    echo "  headref: \${headref}"
  else
    echo "- path: \$path"
    echo "  exists: false"
  fi
}
check_repo "$repo"
EOSH
  )"
done

cat > "$YAML" <<YML
wz_diag:
  timestamp_utc: "$TS"
  termux:
    uname: "$TERMUX_INFO"
    android_version: "${ANDROID_SDK:-unknown}"
    tools:
      git: "$GIT_V"
      ssh: "$SSH_V"
      go: "$GO_V"
      python3: "$PY_V"
      pip: "$PIP_V"
      psql: "$PSQL_V"
      sqlc: "$SQLC_V"
      docker: "$DOCKER_V"
    local_repos:
$(echo "$LOCAL_REPO_REPORT" | sed 's/^/      /')
    secrets:
$(echo "$SECRETS_REPORT" | sed 's/^/      /')
    ssh_to_vps: "$( [ "$SSH_OK" = "OK" ] && echo OK || echo FAIL )"
  vps:
$(echo "$REMOTE_REPORT" | sed 's/^/    /')
YML

cat > "$MD" <<MD
# WZ Diagnostics — Termux + VPS
**UTC:** $TS

## Termux
- uname: \`$TERMUX_INFO\`
- Android: \`$ANDROID_SDK\`

### tools
- git: \`$GIT_V\`
- ssh: \`$SSH_V\`
- go: \`$GO_V\`
- python3: \`$PY_V\`
- pip: \`$PIP_V\`
- psql: \`$PSQL_V\`
- sqlc: \`$SQLC_V\`
- docker: \`$DOCKER_V\`

### local repos
$(echo "$LOCAL_REPO_REPORT" | sed 's/^/- /')

### secrets (masked)
$(echo "$SECRETS_REPORT" | sed 's/^/- /')

### ssh → VPS ($SSH_HOST:$SSH_PORT)
- status: $( [ "$SSH_OK" = "OK" ] && echo "**OK**" || echo "**FAIL**" )

## VPS
$(echo "$REMOTE_REPORT" | sed 's/^/> /')

---
**YAML:** $YAML  
**MD:** $MD
MD

echo "[OK] YAML: $YAML"
echo "[OK] MD  : $MD"
