#!/data/data/com.termux/files/usr/bin/bash -l
# WZ Fractal Bootstrap v1.3 — Hyper-Optimized Termux Deployment
set -eo pipefail
IFS=$'\n\t'

### === Atomic Initialization ===
declare -rx WZ_HOME="$HOME"
declare -rx FRACTAL_DIR="$WZ_HOME/wz-fractal"
declare -rx CORE_DIR="$WZ_HOME/wheelzone-script-utils/scripts/core"
declare -rx CONFIG_FILE="$CORE_DIR/wz_config.sh"
declare -rx RULE_FILE="$WZ_HOME/wz-wiki/rules/escalator_always_on.md"
declare -rx LOG_DIR="$WZ_HOME/.wz_logs"

mkdir -p \
  "$FRACTAL_DIR"/{nodes,config,modules,.cache,logs} \
  "$CORE_DIR" \
  "$LOG_DIR" \
  "$WZ_HOME/wz-wiki/rules"

### === Secure Config v3.3 ===
cat > "$CONFIG_FILE" <<'CFG_EOF'
#!/data/data/com.termux/files/usr/bin/bash -l
set -euo pipefail

declare -rx LOKI_URL="http://localhost:3100/loki/api/v1/push"
declare -ix LOKI_RETRIES=3
declare -ix LOKI_TIMEOUT=5

declare -rax CRITICAL_PATTERNS=("контр" "critical" "urgent" "security" "аварийн" "нарушен")
declare -rax WARNING_PATTERNS=("\\?" "warn" "attention" "провер" "review" "внимание")

declare -rx WZ_LOG_DIR="$HOME/.wz_logs"
declare -rx WZ_CACHE_DIR="$HOME/.wz_cache"
declare -rx WZ_CORE_DIR="$HOME/wheelzone-script-utils/scripts/core"

if [[ -n "${TERMUX_VERSION:-}" ]]; then
  declare -rx TERMUX_MODE=true
  declare -rx NOTIFICATION_SOUND="$PREFIX/share/sounds/alert.mp3"
else
  declare -rx TERMUX_MODE=false
fi
CFG_EOF

chmod 640 "$CONFIG_FILE"

### === Fractal Core v1.3 ===
cat > "$FRACTAL_DIR/core.sh" <<'CORE_EOF'
#!/bin/bash
set -eo pipefail
IFS=$'\n\t'

node_processor() {
  local node_dir="$1"
  local config="$node_dir/config.yaml"
  [[ -f "$config" ]] || return

  local node_id node_level
  node_id=$(yq e '.node.id // "unnamed"' "$config")
  node_level=$(yq e '.node.level // 0' "$config")

  printf "%(%Y-%m-%dT%H:%M:%S)T|%d|%s|ACTIVE\n" -1 "$node_level" "$node_id" >> "${LOG_DIR:-$HOME/wz-fractal/logs}/fractal.log"

  while IFS= read -r module; do
    [[ -x "$node_dir/modules/${module}.sh" ]] && "$node_dir/modules/${module}.sh" "$node_dir" &
  done < <(yq e '.node.modules[]?' "$config")

  while IFS= read -r child; do
    node_processor "$node_dir/nodes/$child"
  done < <(yq e '.node.children[]?' "$config")

  wait
}

main() {
  export LOG_DIR="${LOG_DIR:-$HOME/wz-fractal/logs}"
  mkdir -p "$LOG_DIR"
  node_processor "$HOME/wz-fractal"
}

main "$@"
CORE_EOF

### === Escalation Module ===
cat > "$FRACTAL_DIR/modules/escalation.sh" <<'ESC_EOF'
#!/bin/bash
set -eo pipefail

declare -r node_dir="$1"
declare -r config="$node_dir/config.yaml"
declare -r cache_db="$HOME/wz-fractal/.cache/escalation.db"
declare -r comm_file="$HOME/wz-fractal/.comm"

mkdir -p "${cache_db%/*}"
sqlite3 "$cache_db" "CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  timestamp INTEGER,
  message_hash TEXT UNIQUE,
  severity TEXT CHECK(severity IN ('info','warning','critical'))
);" 2>/dev/null

process_alert() {
  local msg="$1"
  local msg_hash=$(openssl sha256 <<<"$msg" | cut -d' ' -f2)
  local cutoff=$(($(date +%s) - 300))

  [[ -n $(sqlite3 "$cache_db" "SELECT 1 FROM alerts WHERE message_hash='$msg_hash' AND timestamp > $cutoff LIMIT 1;") ]] && return

  local severity="info"
  while IFS= read -r pattern; do
    [[ "$msg" =~ $pattern ]] && { severity="critical"; break; }
  done < <(yq e '.escalation.critical_patterns[]?' "$config")

  [[ "$severity" == "info" ]] && while IFS= read -r pattern; do
    [[ "$msg" =~ $pattern ]] && { severity="warning"; break; }
  done < <(yq e '.escalation.warning_patterns[]?' "$config")

  sqlite3 "$cache_db" "INSERT OR IGNORE INTO alerts VALUES (
    '$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py)', 
    $(date +%s), 
    '$msg_hash', 
    '$severity'
  );"
  echo "$severity:$msg" >> "$comm_file"
}

while read -r input; do
  process_alert "$input" &
  (( $(jobs -r | wc -l) >= $(nproc) )) && wait -n
done < <(cat -)
wait
ESC_EOF

### === Core Node YAML ===
cat > "$FRACTAL_DIR/config/core.yaml" <<'YAML_EOF'
node:
  id: "root"
  level: 0
  modules: ["escalation"]

escalation:
  critical_patterns: 
    - "контр"
    - "critical"
    - "security"
    - "аварийн"
  warning_patterns:
    - "\\?"
    - "warn"
    - "внимание"
YAML_EOF

### === Rule Markdown ===
cat > "$RULE_FILE" <<'RULE_EOF'
# Rule: escalator_always_on

**Описание:**
Постоянно работающий модуль эскалации в системе WZ Fractal. 
Обрабатывает потоки сообщений, определяет уровень угрозы, сохраняет в SQLite, пишет в .comm

**Ключевые особенности:**
- SHA256-хеш сообщений
- Кэш на основе SQLite
- Чувствительность к паттернам: "контр", "critical", "аварийн"

**Аудит:**
```bash
sqlite3 ~/wz-fractal/.cache/escalation.db "SELECT * FROM alerts ORDER BY timestamp DESC LIMIT 10;"

RULE_EOF

chmod 750 "$FRACTAL_DIR/core.sh" "$FRACTAL_DIR/modules/escalation.sh"

echo "✅ bootstrap_fractal_v1.3.sh успешно создан. Запуск: bash ~/wheelzone-script-utils/bootstrap/bootstrap_fractal_v1.3.sh" EOF
