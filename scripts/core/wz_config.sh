#!/data/data/com.termux/files/usr/bin/bash -l
# uuid: 2025-08-26T13:20:14+03:00-1012379743
# title: wz_config.sh
# component: scripts
# updated_at: 2025-08-26T13:20:14+03:00

set -euo pipefail

declare -rx FRACTAL_MAX_DEPTH=10
declare -rax FRACTAL_MODULES=("escalation" "logging" "monitoring")

declare -rax CRITICAL_PATTERNS=("контр" "critical" "аварийн")
declare -rax WARNING_PATTERNS=("\\?" "warn" "внимание")

declare -rx WZ_LOG_DIR="$HOME/.wz_logs"
declare -rx WZ_CACHE_DIR="$HOME/.wz_cache"
