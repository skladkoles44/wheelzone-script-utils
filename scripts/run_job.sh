#!/usr/bin/env bash
# eof
set -euo pipefail
exec 9>/tmp/job.lock
flock -n 9 || exit 0

do_job() {
  find . -name '*.txt' -print0 | xargs -0 -P4 -I{} sh -c 'process "$1"' _ {}
}
do_job
