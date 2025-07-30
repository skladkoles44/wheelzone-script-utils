#!/data/data/com.termux/files/usr/bin/bash -l
set -euo pipefail

declare -rx FRACTAL_MAX_DEPTH=10
declare -rax FRACTAL_MODULES=("escalation" "logging" "monitoring")

declare -rax CRITICAL_PATTERNS=("контр" "critical" "аварийн")
declare -rax WARNING_PATTERNS=("\\?" "warn" "внимание")

declare -rx WZ_LOG_DIR="$HOME/.wz_logs"
declare -rx WZ_CACHE_DIR="$HOME/.wz_cache"
