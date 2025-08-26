#!/usr/bin/env bash
# WZ UUID Bridge — подключает ретро-ядро и нормализует имя генератора.
set -o pipefail
__WZ_CANON__="/data/data/com.termux/files/home/wheelzone-script-utils/cron/wz_history_core.sh"

# мягкий source в сабшелле (если в ядре есть exit — сессию не убьём)
set +u +e
( . "$__WZ_CANON__" ) || true
set -e -u || true

# В ретро-ядре каноничное имя: fractal_uuid → даём стандартный алиас
if ! type -t generate_fractal_uuid >/dev/null 2>&1; then
  if type -t fractal_uuid >/dev/null 2>&1; then
    generate_fractal_uuid(){ fractal_uuid "$@"; }
  fi
fi

type -t generate_fractal_uuid >/dev/null 2>&1 || { echo "ERR: canon loaded but no generator function"; exit 4; }

# Единый маршрут для всех старых имён
wz_uuid(){ generate_fractal_uuid "$@"; }
wz_fractal_uuid(){ generate_fractal_uuid "$@"; }
generate_uuid(){ generate_fractal_uuid "$@"; }
fractal_uuid_alias(){ generate_fractal_uuid "$@"; }  # на всякий
