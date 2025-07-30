#!/usr/bin/env bash
# wz_generate_diagram.sh v1.2.1 — WheelZone Git Repository Tree Diagram Generator

set -euo pipefail
LOG_FILE="$HOME/wheelzone-script-utils/logs/generate_diagram.log"

REPO_ROOT="$HOME"
WIKI_REPO="$REPO_ROOT/wz-wiki"
SCRIPTS_REPO="$REPO_ROOT/wheelzone-script-utils"
OUT_DIR="$WIKI_REPO/docs/architecture"
MERMAID_FILE="$OUT_DIR/git_repository_tree_mermaid.md"
TREE_FILE="$OUT_DIR/git_repository_tree.md"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S)"

mkdir -p "$OUT_DIR"

{
  echo "# WheelZone Git Repository Tree Diagram"
  echo "_Generated on $TIMESTAMP"
  echo '```bash'
  (cd "$REPO_ROOT" && tree -a -I ".git|__pycache__|.ipynb_checkpoints|node_modules|*.log" -N wz-wiki wheelzone-script-utils)
  echo '```'
} >"$TREE_FILE"

{
  echo "## Mermaid Diagram"
  echo "_Generated on $TIMESTAMP"
  echo '```mermaid'
  echo "graph TD"
  (cd "$REPO_ROOT" && find wz-wiki wheelzone-script-utils -type d | sed 's|^|    |' | while read -r dir; do
    parent=$(dirname "$dir")
    [ "$parent" != "$dir" ] && echo "    \"$parent\" --> \"$dir\""
  done)
  echo '```'
} >"$MERMAID_FILE"

touch "$OUT_DIR/.gitkeep"

echo "{\"level\":\"INFO\",\"ts\":\"$(date +%Y-%m-%dT%H:%M:%S)\",\"event\":\"done\",\"script\":\"wz_generate_diagram\"}" >>"$LOG_FILE"
