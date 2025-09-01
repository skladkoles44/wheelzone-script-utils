#!/usr/bin/env bash
# WZ UUID Bridge (Termux/Android15): normalize name to generate_fractal_uuid
set -o pipefail
__WZ_CANON__="/data/data/com.termux/files/home/wheelzone-script-utils/cron/wz_history_core.sh"

# мягкий source в сабшелле: ретро-ядро может делать exit/set -u
set +u +e
( . "$__WZ_CANON__" ) || true
set -e -u || true

# если стандарта нет — алиасим на fractal_uuid
if ! type -t generate_fractal_uuid >/dev/null 2>&1; then
  if type -t fractal_uuid >/dev/null 2>&1; then
    generate_fractal_uuid(){ fractal_uuid "$@"; }
  fi
fi

type -t generate_fractal_uuid >/dev/null 2>&1 || { echo "ERR: no generator function after sourcing canon"; exit 4; }

# старые имена → единый маршрут
fractal_uuid(){ generate_fractal_uuid "$@"; }   # сохраняем привычку
wz_uuid(){ generate_fractal_uuid "$@"; }
wz_fractal_uuid(){ generate_fractal_uuid "$@"; }
generate_uuid(){ generate_fractal_uuid "$@"; }
