#!/usr/bin/env bash
# wz_chatend.sh v2.5-dev — генератор отчётов завершённых чатов (Markdown+YAML/JSON)

set -euo pipefail

# ==== CONFIG ====
CONFIG_FILE="$HOME/.config/wz_chatend.conf"
INSIGHTS_FILE="${INSIGHTS_FILE:-$HOME/wzbuffer/tmp_insights.txt}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/wz-knowledge/WZChatEnds}"
SCRIPT_VERSION="2.5-dev"
FORMAT="yaml"
UUID_STRATEGY="content"

# ==== LOAD CONFIG ====
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# ==== DEPENDENCY CHECK ====
check_dependencies() {
  local missing=0
  for cmd in bash sha256sum uuidgen python3; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing: $cmd"; missing=1; }
  done
  [[ "$missing" -eq 1 ]] && exit 2
}

# ==== USAGE ====
print_help() {
  cat <<EOF
wz_chatend.sh v$SCRIPT_VERSION
Usage: wz_chatend.sh [--help] [--version] [--format yaml|json] [--uuid-strategy content|random]

Options:
  --help               Show this help message
  --version            Show script version
  --format FORMAT      Output metadata in yaml (default) or json
  --uuid-strategy STR  UUID generation: content (default) or random
