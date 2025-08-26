#!/data/data/com.termux/files/usr/bin/bash -l
# uuid: 2025-08-26T13:19:42+03:00-3684727051
# title: wz_check_recursion.sh
# component: .
# updated_at: 2025-08-26T13:19:42+03:00

# WZ Recursion Scanner v2.1 — Atomic Pattern Finder
set -euo pipefail
shopt -s globstar nullglob

declare -ra TARGET_DIRS=(
    "$HOME/wheelzone-script-utils"
    "$HOME/bin"
    "$HOME/.termux"
)

scan() {
    local file pattern
    for file in "${TARGET_DIRS[@]}"/**/*.sh; do
        [[ -f "$file" ]] || continue
        
        # Быстрая проверка через ripgrep (если доступен)
        if command -v rg &>/dev/null; then
            rg -n --color=always \
               -e 'bash\s+(?!-[-a-z]+\s+)*\w' \
               -e 'source\s+\w' \
               -e '\.\s+\w' \
               -e 'exec\s+.*bash' \
               "$file"
        else
            grep -n --color=auto \
                 -E 'bash\s+[^-][^ ]*|source\s+|\.\s|\bexec\s+.*bash' \
                 "$file"
        fi
    done | tee "$HOME/.wz_logs/wz_recursion_scan_$(date +%s).log"
}

main() {
    echo "🔍 Scanning:" >&2
    printf "  - %s\n" "${TARGET_DIRS[@]}" >&2
    scan
    echo -e "\n✅ Log saved: $HOME/.wz_logs/wz_recursion_scan_*.log" >&2
}

main "$@"
