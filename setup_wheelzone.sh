#!/bin/bash
# Setup WheelZone full environment - Termux / Android
# Version 1.0.0

set -euo pipefail
IFS=$'\n\t'

# === Config ===
WZ_HOME="$HOME/wheelzone-script-utils"
WIKI_HOME="$HOME/wz-wiki"
BUFFER="$HOME/wzbuffer"
GIT_USER="your-github-username"  # заменишь на свой namespace
GIT_EMAIL="your-email@example.com"
REPOS=("wheelzone-script-utils" "wz-wiki")
DIRS=("cli" "mobile" "cron" "tests" "monitoring" "configs" "scripts" "tools" "templates")

# === Functions ===
create_dirs() {
    local base=$1
    shift
    for d in "$@"; do
        mkdir -p "$base/$d"
        touch "$base/$d/.gitkeep"
    done
}

setup_git() {
    local repo_dir=$1
    git -C "$repo_dir" init || true
    git -C "$repo_dir" config user.name "$GIT_USER"
    git -C "$repo_dir" config user.email "$GIT_EMAIL"
    git -C "$repo_dir" add .
    git -C "$repo_dir" commit -m "Initial commit" || true
}

# === Execution ===
echo "[WZ] Creating main directories..."
mkdir -p "$WZ_HOME" "$WIKI_HOME" "$BUFFER"

echo "[WZ] Creating wheelzone-script-utils structure..."
create_dirs "$WZ_HOME" "${DIRS[@]}"

echo "[WZ] Creating wz-wiki structure..."
create_dirs "$WIKI_HOME" "rules" "WZChatEnds" "docs" "tools" "registry"

echo "[WZ] Initializing git repositories..."
setup_git "$WZ_HOME"
setup_git "$WIKI_HOME"

echo "[WZ] Environment setup complete."
