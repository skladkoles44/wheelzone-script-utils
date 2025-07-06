#!/data/data/com.termux/files/usr/bin/bash

# 📛 Файл: wz_generate_diagram.sh
# 🧠 Назначение: генерирует Markdown и Mermaid-диаграммы структуры Git-репозиториев
# 📦 Папка: ~/wz-wiki/docs/architecture/
# 🛡️ Production-оптимизирован: логирование, безопасность, атомарность
# 📅 Версия: 1.3.0-prod

set -euo pipefail
IFS=$'\n'

ARCH_DIR="$HOME/wz-wiki/docs/architecture"
REPO_DIR="$HOME/wz-wiki"
DATE=$(date +%Y-%m-%dT%H:%M:%S)
LOG_FILE="$ARCH_DIR/wz_generate_diagram.log"
INSIGHT_FILE="${INSIGHT_FILE:-$HOME/wzbuffer/tmp_insights.txt}"
LOCKFILE="$ARCH_DIR/.wz_generate_diagram.lock"

exec 200>"$LOCKFILE"
flock -n 200 || {
  echo "{\"level\":\"ERROR\",\"ts\":\"$DATE\",\"event\":\"lock_failed\",\"msg\":\"Script is already running\"}" >> "$LOG_FILE"
  exit 1
}

mkdir -p "$ARCH_DIR"
echo "{\"level\":\"INFO\",\"ts\":\"$DATE\",\"event\":\"start\",\"script\":\"wz_generate_diagram\"}" >> "$LOG_FILE"

# Гарантированное наличие .gitkeep
touch "$ARCH_DIR/.gitkeep"
git -C "$REPO_DIR" add "docs/architecture/.gitkeep"

# Markdown
echo "{\"level\":\"INFO\",\"ts\":\"$DATE\",\"event\":\"gen_markdown\",\"msg\":\"Start генерация Markdown\"}" >> "$LOG_FILE"
{
  printf "# 📁 Репозиторий: wz-wiki\n"
  cd "$HOME/wz-wiki"
  find . -type f -print0 | LC_ALL=C sort -z | tr '\0' '\n' | sed 's|^|-- |'

  printf "\n---\n\n# 📁 Репозиторий: wheelzone-script-utils\n"
  cd "$HOME/wheelzone-script-utils"
  find . -type f -print0 | LC_ALL=C sort -z | tr '\0' '\n' | sed 's|^|-- |'
} > "$ARCH_DIR/git_repository_tree.md"

# Mermaid
echo "{\"level\":\"INFO\",\"ts\":\"$DATE\",\"event\":\"gen_mermaid\",\"msg\":\"Start генерация Mermaid\"}" >> "$LOG_FILE"
{
  echo '```mermaid'
  echo 'graph TD'

  echo "subgraph wz-wiki"
  cd "$HOME/wz-wiki"
  find . -type f -print0 | LC_ALL=C sort -z | tr '\0' '\n' | sed 's|^\./||' | while read -r file; do
    IFS='/' read -ra parts <<< "$file"
    parent="wz-wiki"
    for i in "${!parts[@]}"; do
      child="${parts[$i]}"
      id="${parent//[\/.]/__}-${child//[\/.]/__}"
      echo "$parent --> $id[$child]"
      parent="$id"
    done
  done
  echo "end"

  echo "subgraph wheelzone-script-utils"
  cd "$HOME/wheelzone-script-utils"
  find . -type f -print0 | LC_ALL=C sort -z | tr '\0' '\n' | sed 's|^\./||' | while read -r file; do
    IFS='/' read -ra parts <<< "$file"
    parent="wheelzone-script-utils"
    for i in "${!parts[@]}"; do
      child="${parts[$i]}"
      id="${parent//[\/.]/__}-${child//[\/.]/__}"
      echo "$parent --> $id[$child]"
      parent="$id"
    done
  done
  echo "end"
  echo '```'
} > "$ARCH_DIR/git_repository_tree_mermaid.md"

# Git push
echo "{\"level\":\"INFO\",\"ts\":\"$DATE\",\"event\":\"git_push\",\"msg\":\"Пушим обновления\"}" >> "$LOG_FILE"
cd "$REPO_DIR"
git add docs/architecture/git_repository_tree*.md
git diff --cached --quiet || git commit -m "docs: auto-update диаграмм структуры файлов ($DATE)"
git push

# INSIGHT блок
echo "{\"level\":\"INFO\",\"ts\":\"$DATE\",\"event\":\"write_insight\",\"msg\":\"INSIGHT -> $INSIGHT_FILE\"}" >> "$LOG_FILE"
mkdir -p "$(dirname "$INSIGHT_FILE")"
printf -- "- type: INSIGHT\n  title: Обновлены диаграммы Git\n  timestamp: %s\n  files:\n    - %s\n    - %s\n" \
  "$DATE" \
  "docs/architecture/git_repository_tree.md" \
  "docs/architecture/git_repository_tree_mermaid.md" >> "$INSIGHT_FILE"

echo "{\"level\":\"INFO\",\"ts\":\"$(date +%Y-%m-%dT%H:%M:%S)\",\"event\":\"done\",\"script\":\"wz_generate_diagram\"}" >> "$LOG_FILE"
