
source "$HOME/wheelzone-script-utils/scripts/utils/generate_uuid.sh"
#!/data/data/com.termux/files/usr/bin/bash
# generate_uuid.sh — Универсальный UUID-генератор (Termux/VPS)

set -euo pipefail
IFS=$'\n\t'

generate_quantum_uuid() {
  if command -v $(generate_quantum_uuid) >/dev/null 2>&1; then
    $(generate_quantum_uuid)
  elif [[ -f /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    date +%s%N | sha256sum | base64 | head -c 32
  fi
}

generate_quantum_uuid "$@"
