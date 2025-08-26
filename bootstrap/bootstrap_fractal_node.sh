#!/bin/bash
# uuid: 2025-08-26T13:19:50+03:00-3803334415
# title: bootstrap_fractal_node.sh
# component: bootstrap
# updated_at: 2025-08-26T13:19:51+03:00

# WZ Fractal Node Installer v3.1.0 — WZ Noiton Ready
set -eo pipefail
IFS=$'\n\t'

echo "🌀 Инициализация фрактального узла..."

# == 0. Fractal ID ==
generate_fractal_id() {
  local platform=$1
  local entropy=$(shuf -i 1000-9999 -n 1)
  local timestamp=$(date +%s | rev | cut -c 1-4)
  echo "${platform}-${entropy}-${timestamp}"
}

# == 1. Dependencies ==
check_dependencies() {
  echo "🔍 Проверка зависимостей..."
  REQUIRED=(bash yq curl jq git python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py tree)
  MISSING=()
  for bin in "${REQUIRED[@]}"; do
    command -v "$bin" &>/dev/null || MISSING+=("$bin")
  done

  if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "❌ Отсутствуют: ${MISSING[*]}"
    if [[ "$PLATFORM" == "termux" ]]; then
      pkg update && pkg install -y "${MISSING[@]}"
    else
      sudo apt-get update && sudo apt-get install -y "${MISSING[@]}"
    fi
  fi
}

# == 2. Init Node ==
init_node() {
  if [[ -d "/data/data/com.termux/files" ]]; then
    PLATFORM="termux"
    INSTALL_CMD="pkg install -y"
    termux-setup-storage 2>/dev/null || true
  else
    PLATFORM="vps"
    INSTALL_CMD="sudo apt install -y"
  fi

  NODE_ID=$(generate_fractal_id "$PLATFORM")
  UUID=$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)
  SLUG="fractal-${PLATFORM}-$(date +%m%d)"

  declare -Ag DIRS=(
    [CORE]="$HOME/wz-fractal/nodes/node-${UUID::8}"
    [CACHE]="$HOME/wz-fractal/.cache/fractal-${UUID:0:4}"
    [LOGS]="$HOME/.wz_logs/fractal-$(date +%Y%m)"
  )
  for d in "${DIRS[@]}"; do mkdir -p "$d"; done

  CONFIG_FILE="${DIRS[CORE]}/config.fractal.yaml"
  cat > "$CONFIG_FILE" <<EOF
meta:
  id: "$NODE_ID"
  uuid: "$UUID"
  slug: "$SLUG"
  fractal_level: 0
  platform: "$PLATFORM"

modules:
  core: ["git_sync", "healthcheck"]
  optional: ["loki_push", "cache_cleaner", "notion_push"]

network:
  log_server: "https://logs.wheelzone.ru/loki"

storage:
  cache_dir: "${DIRS[CACHE]}"
  max_age_days: 7

git:
  repo_path: "$HOME/wz-wiki"
  sync_interval: 3600
