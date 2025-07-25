#!/data/data/com.termux/files/usr/bin/bash
set -e

# WZ Notify Wrapper v2.5 — Dual Backend (legacy + atomic)

SCRIPT_DIR="$(dirname "$0")"
LEGACY_PY="$SCRIPT_DIR/wz_notify.py"
ATOMIC_PY="$SCRIPT_DIR/wz_notify_atomic.py"

USE_ATOMIC=false

# Фильтрация аргументов
FILTERED_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--atomic" ]]; then
    USE_ATOMIC=true
  else
    FILTERED_ARGS+=("$arg")
  fi
done

# Запуск соответствующего движка
if $USE_ATOMIC; then
  exec python3 "$ATOMIC_PY" "${FILTERED_ARGS[@]}"
else
  exec python3 "$LEGACY_PY" "${FILTERED_ARGS[@]}"
fi
