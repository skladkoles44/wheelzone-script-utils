#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:46+03:00-1444908013
# title: autofix_all.sh
# component: .
# updated_at: 2025-08-26T13:19:46+03:00

# tools/autofix_all.sh — Автоформатирование и исправление по WZ

set -eo pipefail
shopt -s globstar

echo "[WZ] 🔧 Автофиксы активированы..."

# Установка shfmt, black, isort, если не установлены
command -v shfmt >/dev/null || pkg install -y shfmt
command -v black >/dev/null || pip install black
command -v isort >/dev/null || pip install isort

# Фикс Bash-скриптов
find scripts/**/*.sh tools/**/*.sh -type f 2>/dev/null | while read -r f; do
	sed -i '1s|^.*$|#!/data/data/com.termux/files/usr/bin/bash|' "$f"
	chmod +x "$f"
	shfmt -w "$f" || true
done

# Фикс Python-скриптов
find scripts/**/*.py tools/**/*.py -type f 2>/dev/null | while read -r f; do
	sed -i '1s|^.*$|#!/data/data/com.termux/files/usr/bin/python3|' "$f"
	chmod +x "$f"
	isort "$f" || true
	black "$f" || true
done

echo "[WZ] ✅ AutoFix завершён"
# --- [printf_safety_fix] ---
echo "🔧 printf_safety_fix (Termux-safe printf -- protection)"
find scripts/ -type f -name "*.sh" | while read -r f; do
	sed -i -E 's/printf[[:space:]]+"([^"]+)"/printf -- "***REMOVED***"/g' "$f"
done
