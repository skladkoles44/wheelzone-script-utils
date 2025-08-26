#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:35+03:00-391065461
# title: generate_core_docs.sh
# component: .
# updated_at: 2025-08-26T13:19:35+03:00

#TERMUX_HYPEROS_OPTIMIZED
set -eo pipefail

# HyperOS-specific adjustments
export TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
export PYTHONUNBUFFERED=1
export OOM_SCORE_ADJ="-200"  # Reduce OOM killer probability

# Security - Zero Trust model
declare -r CORE_YAML="/data/data/com.termux/files/home/wz-wiki/core/core.yaml"
declare -r OUT_DIR="/data/data/com.termux/files/home/wz-wiki/docs/core"
declare -r LOCK_FILE="${OUT_DIR}/.generate.lock"
declare -r LOG_FILE="${OUT_DIR}/generate.log"
declare -r PID_FILE="/data/data/com.termux/files/usr/var/run/generate_core_docs.pid"

# Termux API integration
if ! command -v termux-wake-lock &>/dev/null; then
    echo "WARNING: Termux API not available" >&2
else
    termux-wake-lock -n "CoreDocsGen" &>/dev/null
fi

# Cleanup function with HyperOS process handling
cleanup() {
    [ -f "$LOCK_FILE" ] && rm -f "$LOCK_FILE"
    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
    termux-wake-unlock "CoreDocsGen" &>/dev/null || true
    kill -TERM 0 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# OOM Killer protection
echo "-200" > /proc/$$/oom_score_adj || true

# Process management
if [ -f "$PID_FILE" ]; then
    if ps -p $(cat "$PID_FILE") &>/dev/null; then
        echo "Process already running (PID: $(cat "$PID_FILE"))" >&2
        exit 1
    else
        rm -f "$PID_FILE"
    fi
fi
echo $$ > "$PID_FILE"

# Resource-efficient logging
exec 2> >(while read -r line; do 
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $line" >> "$LOG_FILE"
done)
exec 1> >(while read -r line; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $line" >> "$LOG_FILE"
done)

# Main execution with crash recovery
retry_count=0
max_retries=3
backoff_seconds=5

while [ $retry_count -lt $max_retries ]; do
    if python3 - <<PYEOF; then
import yaml, os, json, datetime
from contextlib import ExitStack

def secure_path(base, *parts):
    base = os.path.abspath(base)
    path = os.path.abspath(os.path.join(base, *parts))
    if not path.startswith(base):
        raise ValueError(f"Path traversal detected: {path}")
    return path

try:
    # HyperOS-compatible file ops
    os.makedirs("$OUT_DIR/layers", exist_ok=True)
    os.makedirs("$OUT_DIR/modules", exist_ok=True)

    with open("$CORE_YAML", 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f) or {}

    layers = data.get("core", {}).get("layers", {})
    if not layers:
        print(json.dumps({
            "level": "WARNING",
            "message": "No layers found",
            "lang": "en",
            "timestamp": datetime.datetime.utcnow().isoformat()
        }))

    with ExitStack() as stack:
        # Memory-efficient file handling
        files = {
            'readme': stack.enter_context(
                open(secure_path("$OUT_DIR", "README_core.md"), 'a', encoding='utf-8')
            )
        }

        for lname, lcontent in layers.items():
            lid = str(lname).upper()
            modules = lcontent.get("modules", [])

            # Atomic writes with temp files
            layer_temp = secure_path("$OUT_DIR", "layers", f".{lname}.tmp")
            modules_temp = secure_path("$OUT_DIR", "modules", f".{lname}_modules.tmp")

            with open(layer_temp, 'w', encoding='utf-8') as lf, \
                 open(modules_temp, 'w', encoding='utf-8') as mf:
                
                lf.write(f"# Layer: {lid}\n\n")
                mf.write(f"# Modules in {lid}\n\n")

                for mod in modules:
                    mod_id = str(mod.get('id', 'UNKNOWN')).strip()
                    desc = str(mod.get('description', 'No description')).replace('\n', ' ')
                    
                    lf.write(f"## {mod_id}\n{desc}\n\n")
                    mf.write(f"- **{mod_id}**: {desc}\n")

            # Atomic rename
            os.replace(layer_temp, secure_path("$OUT_DIR", "layers", f"{lname}.md"))
            os.replace(modules_temp, secure_path("$OUT_DIR", "modules", f"{lname}_modules.md"))

            files['readme'].write(f"- [{lid}](layers/{lname}.md)\n")

    # HyperOS background process stability
    os.sync()
    print(json.dumps({
        "level": "SUCCESS",
        "message": "Generation completed",
        "lang": "en",
        "timestamp": datetime.datetime.utcnow().isoformat()
    }))

except Exception as e:
    print(json.dumps({
        "level": "CRITICAL",
        "message": str(e),
        "lang": "en",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "exception": type(e).__name__
    }))
    raise SystemExit(1)
PYEOF
        break
    else
        retry_count=$((retry_count + 1))
        sleep $backoff_seconds
        backoff_seconds=$((backoff_seconds * 2))
    fi
done

[ $retry_count -eq $max_retries ] && {
    echo "Maximum retries exceeded" >&2
    exit 1
}

exit 0
