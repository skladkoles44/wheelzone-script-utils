#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:44+03:00-2178638675
# title: wz_checklist_engine.sh
# component: .
# updated_at: 2025-08-26T13:19:44+03:00

# WZ Checklist Engine v3.1 — Fractal Edition (виджет+UI+логика+снапшоты)

set -euo pipefail
shopt -s failglob

CONFIG_DIR="$HOME/.config/wz-checklist"
STATE_FILE="$CONFIG_DIR/state.json"
BACKSTACK_FILE="$CONFIG_DIR/backstack.json"
TMP_FILE="$CONFIG_DIR/temp.json"
LOG_FILE="$CONFIG_DIR/checklist.log"
IDENTITY_FILE="$CONFIG_DIR/identity.json"
NOTIFIER="$HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh"
SNAPSHOT_DIR="$HOME/wz-snapshots"

init_engine() {
  mkdir -p "$CONFIG_DIR" "$SNAPSHOT_DIR"
  [ -f "$STATE_FILE" ] || generate_initial_state
  [ -f "$IDENTITY_FILE" ] || generate_identity
  [ -f "$LOG_FILE" ] || touch "$LOG_FILE"
  check_dependencies || {
    termux-toast "❌ Требуются: termux-api, jq"
    exit 1
  }
  log "Engine initialized v3.1"
}

generate_initial_state() {
  cat > "$STATE_FILE" <<EOF_JSON
{
  "version": "3.1",
  "system": {
    "initialized_at": "$(date --iso-8601=seconds)",
    "last_updated": "$(date +%Y-%m-%dT%H:%M:%S%z)"
  },
  "tasks": {
    "core": {
      "uuid": {
        "engine_registered": {
          "status": false,
          "uuid": "$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)",
          "description": "Регистрация UUID движка"
        },
        "refactored": {
          "status": false,
          "uuid": "$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)",
          "description": "Рефакторинг кода"
        }
      },
      "snapshot": {
        "created": {
          "status": false,
          "uuid": "$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)",
          "description": "Создание снапшота"
        },
        "uploaded": {
          "status": false,
          "uuid": "$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)",
          "description": "Загрузка снапшота"
        }
      }
    }
  }
}
EOF_JSON
}

generate_identity() {
  cat > "$IDENTITY_FILE" <<EOF_ID
{
  "node_id": "termux-$(date +%s)",
  "os": "$(uname -o)",
  "arch": "$(uname -m)",
  "created_at": "$(date --iso-8601=seconds)",
  "tags": ["mobile", "termux"]
}
EOF_ID
}

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_dependencies() {
  command -v termux-toast >/dev/null && command -v jq >/dev/null
}

update_task() {
  local task_path="$1"
  local action="${2:-toggle}"
  local new_value

  case "$action" in
    "toggle") new_value=$(jq -r ".tasks.${task_path}.status | not" "$STATE_FILE") ;;
    "complete") new_value=true ;;
    "reset") new_value=false ;;
    *) log "Неизвестное действие: $action"; return 1 ;;
  esac

  jq ".tasks.${task_path}.status = $new_value" "$STATE_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$STATE_FILE"
  local task_name=$(jq -r ".tasks.${task_path}.description" "$STATE_FILE")
  log "Task updated: ${task_name} → $new_value"

  if [[ "$new_value" == "true" ]]; then
    send_notification "$task_path" "$task_name"
    [[ "$task_path" == *"snapshot.created" ]] && create_snapshot
  fi
}

send_notification() {
  local key="$1"
  local name="$2"
  local uuid=$(jq -r ".tasks.${key}.uuid" "$STATE_FILE")
  local node=$(jq -r '.node_id' "$IDENTITY_FILE")
  [[ -x "$NOTIFIER" ]] && "$NOTIFIER" --type "checklist" --uuid "$uuid" \
    --title "☑️ $name" --node "$node" --message "Фрактальная задача выполнена: $key" \
    >/dev/null 2>&1 || log "❗ уведомление не отправлено"
}

create_snapshot() {
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local snap_file="${SNAPSHOT_DIR}/checklist_snapshot_${timestamp}.tar.gz"
  tar czf "$snap_file" "$CONFIG_DIR" && log "Snapshot: $snap_file"
}

reset_state() {
  cp "$STATE_FILE" "${STATE_FILE}.bak.$(date +%s)"
  generate_initial_state
  log "State reset"
  termux-toast "🧹 Состояние сброшено"
}

progress_report() {
  local total=$(jq '[.. | .status? | select(. != null)] | length' "$STATE_FILE")
  local done=$(jq '[.. | .status? | select(. == true)] | length' "$STATE_FILE")
  local percent=$(( done * 100 / total ))
  termux-toast "📊 ${percent}% выполнено"
  echo "Прогресс: ${done}/${total} (${percent}%)"
}

md_export() {
  local file="${CONFIG_DIR}/checklist_report_$(date +%Y%m%d).md"
  jq -r '
    "## WZ Checklist Report\n",
    "**Generated**: \(.system.last_updated)\n\n",
    (.tasks | .. | select(.description?) |
      "### \(.description)\n",
      "- Status: \(.status | if . then "✅" else "❌" end)\n",
      "- UUID: \(.uuid)\n\n"
    )
  ' "$STATE_FILE" > "$file"
  termux-toast "📤 Отчёт: ${file}"
}

show_tasks() {
  echo -e "\n📋 Активные задачи:\n"
  jq -r '
    paths(scalars) as $p 
    | select(getpath($p) | type == "boolean") 
    | {
        path: $p | map(tostring) | join("."),
        value: getpath($p),
        description: try getpath($p[0: -1] + ["description"]) catch "—"
      }
    | "- [\(.value | if . then "x" else " ") ] \(.description) (`\(.path)`)"
  ' "$STATE_FILE"
}

show_menu() {
  while true; do
    clear
    echo "🌀 WZ Checklist Engine v3.1"
    echo "1. Задачи"
    echo "2. Снапшот"
    echo "3. Сброс"
    echo "4. Прогресс"
    echo "5. Экспорт"
    echo "6. Выход"
    read -p "Выбор: " ch
    case "$ch" in
      1) show_tasks ;;
      2) create_snapshot ;;
      3) reset_state ;;
      4) progress_report ;;
      5) md_export ;;
      6) exit 0 ;;
      *) echo "❌" ;;
    esac
    read -p "⏎ для продолжения..."
  done
}

init_engine
[[ "${1:-}" == "--widget" ]] && show_tasks || show_menu
