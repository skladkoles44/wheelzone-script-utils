#!/data/data/com.termux/files/usr/bin/bash
# wz_register_ai_script.sh — Регистрация AI-скрипта в реестре WheelZone
set -euo pipefail

# === Входные параметры ===
script_name="${1:-}"
script_type="${2:-ai}"
script_status="${3:-active}"
registry_name="${4:-}"
desc="${5:-}"
todo_note="${6:-}"

if [[ -z "$script_name" ]]; then
  echo "[!] Укажи имя скрипта, например: wz_ai_capture.sh"
  exit 1
fi

script_path="scripts/${script_type}/${script_name}"
timestamp=$(date -Iseconds)

# === Пути ===
csv1="$HOME/wz-wiki/data/script_event_log.csv"
csv2="$HOME/wz-wiki/data/todo_from_chats.csv"
yaml="registry/${script_type}/${registry_name:-${script_name%.sh}}.yaml"
yaml_path="$HOME/wz-wiki/$yaml"

mkdir -p "$(dirname "$yaml_path")"

# === 1. Добавление в CSV-реестры ===
echo "\"$script_name\",\"$script_type\",\"${registry_name:-${script_name%.sh}}\",\"$script_status\",\"$script_path\",\"PUSHED\",\"$timestamp\"" >> "$csv1"

if [[ -n "$todo_note" ]]; then
  echo "\"$desc\",\"$script_path\",\"$timestamp\",\"$todo_note\"" >> "$csv2"
fi

# === 2. YAML-регистрация (если нет) ===
if [[ ! -f "$yaml_path" ]]; then
  cat > "$yaml_path" <<EOFY
id: ${registry_name:-${script_name%.sh}}
name: ${desc:-${registry_name:-$script_name}}
type: $script_type
path: $script_path
status: $script_status
description: ${desc:-$script_name}
created_at: $timestamp
EOFY
fi

# === 3. Git действия ===
cd "$HOME/wz-wiki"
git add "$csv1" "$csv2" "$yaml_path"
git commit -m "[REG] Register $script_name ($registry_name)"
git push || echo "[!] Git push пропущен"
