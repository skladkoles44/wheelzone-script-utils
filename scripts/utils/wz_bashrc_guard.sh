#!/data/data/com.termux/files/usr/bin/bash -l
# uuid: 2025-08-26T13:19:41+03:00-1088079834
# title: wz_bashrc_guard.sh
# component: .
# updated_at: 2025-08-26T13:19:41+03:00

# WZ Bashrc Guard v2.2 — SHLVL Protector
set -euo pipefail
shopt -s failglob

declare -r BASHRC="$HOME/.bashrc"
declare -r BACKUP="${BASHRC}.bak.$(date +%Y%m%d_%H%M%S)"
declare -r CHECKSUM="$(sha256sum "$BASHRC" 2>/dev/null || echo "new")"

guard() {
    # Атомарное обновление через временный файл
    local tmpfile
    tmpfile="$(mktemp -p "${BASHRC%/*}")"
    
    # Минимальный заголовок
    cat <<'HEADER' > "$tmpfile"
#!/data/data/com.termux/files/usr/bin/bash -l
# WZ-Bashrc (protected)
[[ \$- != *i* ]] && return  # Non-interactive exit
[[ \$SHLVL -gt 2 ]] && return  # Recursion guard
HEADER

    # Фильтрация опасных паттернов
    grep -vE '^(source\s|\.\s|exec\s|bash\s|SHLVL|\[\[ \$-)' "$BASHRC" >> "$tmpfile"
    
    # Атомарная замена
    mv "$tmpfile" "$BASHRC" && chmod 644 "$BASHRC"
}

main() {
    cp "$BASHRC" "$BACKUP" || { echo "❌ Backup failed"; exit 1; }
    echo "📦 Backup: $BACKUP" >&2
    
    guard
    
    echo "✅ Protected:" >&2
    diff --color=always -u "$BACKUP" "$BASHRC" | head -n 10
    echo -e "\nChecksum: $CHECKSUM -> $(sha256sum "$BASHRC")" >&2
}

main "$@"
