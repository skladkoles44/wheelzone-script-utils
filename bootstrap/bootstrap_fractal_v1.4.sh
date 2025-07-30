#!/data/data/com.termux/files/usr/bin/bash -l
# WZ Fractal Bootstrap v1.4 — Fractal-Recursive Expansion Ready
set -eo pipefail
IFS=$'\n\t'

### === Core Paths ===
WZ_HOME="$HOME"
FRACTAL_DIR="$WZ_HOME/wz-fractal"
CORE_DIR="$WZ_HOME/wheelzone-script-utils/scripts/core"
LOG_DIR="$WZ_HOME/.wz_logs"
RULE_FILE="$WZ_HOME/wz-wiki/rules/escalator_always_on.md"
CONFIG_FILE="$CORE_DIR/wz_config.sh"

### === Create Directory Structure ===
mkdir -p \
  "$FRACTAL_DIR"/{nodes,modules,config,.cache,logs} \
  "$CORE_DIR" "$LOG_DIR" "$WZ_HOME/wz-wiki/rules"

### === Write Core Config ===
cat > "$CONFIG_FILE" <<'CFG'
#!/data/data/com.termux/files/usr/bin/bash -l
set -euo pipefail

# Logging & Security Patterns
declare -rx LOKI_URL="http://localhost:3100/loki/api/v1/push"
declare -ix LOKI_RETRIES=3
declare -ix LOKI_TIMEOUT=5
declare -rax CRITICAL_PATTERNS=("контр" "critical" "security" "аварийн")
declare -rax WARNING_PATTERNS=("\\?" "warn" "внимание" "review")

# Paths
declare -rx WZ_LOG_DIR="$HOME/.wz_logs"
declare -rx WZ_CACHE_DIR="$HOME/.wz_cache"
declare -rx WZ_CORE_DIR="$HOME/wheelzone-script-utils/scripts/core"

# Termux Mode
[[ -n "${TERMUX_VERSION:-}" ]] && TERMUX_MODE=true || TERMUX_MODE=false
CFG

chmod 640 "$CONFIG_FILE"

### === Fractal Core Launcher (Recursive) ===
cat > "$FRACTAL_DIR/core.sh" <<'EOF_CORE'
#!/bin/bash
set -eo pipefail
IFS=$'\n\t'

node_processor() {
  local node="$1"
  local cfg="$node/config.yaml"
  [[ -f "$cfg" ]] || return

  local id lvl
  id=$(yq e '.node.id // "unnamed"' "$cfg")
  lvl=$(yq e '.node.level // 0' "$cfg")

  printf "%(%FT%T)T|%d|%s|ACTIVE\n" -1 "$lvl" "$id" >> "${LOG_DIR:-$HOME/wz-fractal/logs}/fractal.log"

  # Run modules
  while read -r m; do
    [[ -x "$node/modules/$m.sh" ]] && "$node/modules/$m.sh" "$node" &
  done < <(yq e '.node.modules[]?' "$cfg")

  # Recursion
  for child in "$node"/nodes/*; do
    [[ -d "$child" ]] && node_processor "$child"
  done

  wait
}

main() {
  export LOG_DIR="${LOG_DIR:-$HOME/wz-fractal/logs}"
  mkdir -p "$LOG_DIR"
  node_processor "$HOME/wz-fractal"
}
main "$@"
EOF_CORE

chmod +x "$FRACTAL_DIR/core.sh"

### === Escalation Module ===
cat > "$FRACTAL_DIR/modules/escalation.sh" <<'EOF_ESC'
#!/bin/bash
set -eo pipefail

node="$1"
cfg="$node/config.yaml"
db="$HOME/wz-fractal/.cache/escalation.db"
comm="$HOME/wz-fractal/.comm"

mkdir -p "${db%/*}"
sqlite3 "$db" "CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  timestamp INTEGER,
  message_hash TEXT UNIQUE,
  severity TEXT CHECK(severity IN ('info','warning','critical'))
);" 2>/dev/null

process_alert() {
  local msg="$1"
  local hash=$(echo -n "$msg" | openssl sha256 | awk '{print $2}')
  local cutoff=$(( $(date +%s) - 300 ))

  sqlite3 "$db" "SELECT 1 FROM alerts WHERE message_hash='$hash' AND timestamp > $cutoff LIMIT 1;" | grep -q 1 && return

  local sev="info"
  while read -r p; do [[ "$msg" =~ $p ]] && { sev="critical"; break; }; done < <(yq e '.escalation.critical_patterns[]?' "$cfg")
  [[ "$sev" == "info" ]] && while read -r p; do [[ "$msg" =~ $p ]] && { sev="warning"; break; }; done < <(yq e '.escalation.warning_patterns[]?' "$cfg")

  sqlite3 "$db" "INSERT OR IGNORE INTO alerts VALUES ('$(uuidgen)', $(date +%s), '$hash', '$sev');"
  echo "$sev:$msg" >> "$comm"
}

while read -r line; do process_alert "$line" & done < <(cat -)
wait
EOF_ESC

chmod +x "$FRACTAL_DIR/modules/escalation.sh"

### === Root Config (Fractal Level 0) ===
cat > "$FRACTAL_DIR/config/core.yaml" <<'YAML'
node:
  id: "root"
  level: 0
  modules: ["escalation"]

escalation:
  critical_patterns: ["контр", "critical", "security", "аварийн"]
  warning_patterns: ["\\?", "warn", "внимание", "review"]
YAML

### === Rule File ===
cat > "$RULE_FILE" <<'RULE'
# Rule: escalator_always_on

**Поведение:**  
- Активен в корневом и дочерних узлах  
- Распознаёт критические паттерны  
- Создаёт SQLite-логи тревог и пишет в `.comm`

**Проверка:**
```bash
sqlite3 ~/wz-fractal/.cache/escalation.db "SELECT * FROM alerts ORDER BY timestamp DESC LIMIT 3;"

RULE

# === Git Push Rule ===

cd "$WZ_HOME/wz-wiki" git add rules/escalator_always_on.md git commit -m "📦 WZ Fractal v1.4 — фрактальная эскалация" git push || echo "⚠️ Git push skipped"

# === Notify (Optional) ===

if [[ -x "$WZ_HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh" ]]; then bash "$WZ_HOME/wheelzone-script-utils/scripts/notion/wz_notify.sh" 
--type "deploy" 
--title "WZ Fractal v1.4 deployed" 
--message "Now supports fractal node recursion" 
--tags "fractal,bootstrap" fi

echo "✅ WZ Fractal v1.4 установлена и готова к работе" EOF
