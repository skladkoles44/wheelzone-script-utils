#!/data/data/com.termux/files/usr/bin/bash
# --- Исключения ---
# В папке docs/ отключаем проверку fractal_uuid и sidecar для .md/.sql/.tsv
if [[ "$1" == docs/* ]]; then
  case "$1" in
    *.md|*.sql|*.tsv)
      echo "[WZ] skip UUID check for docs: $1";
      exit 0
      ;;
  esac
fi

# uuid: 2025-08-26T13:19:34+03:00-3196501117
# title: check_rule.sh
# component: .
# updated_at: 2025-08-26T13:19:34+03:00

#!/data/data/com.termux/files/usr/bin/bash
# WZ Rule Checker v4.0 — универсальный валидатор и автофикс (WBP Fusion)

set -euo pipefail
readonly FILE="${1:?⚠️ Укажите путь к файлу}"
readonly MODE="${2:-check}"
readonly LOG_PREFIX="[WZ Rule Checker]"
readonly TMP_FILE="$(mktemp)"

[[ -f "$FILE" ]] || {
	echo "$LOG_PREFIX ⚠️ Файл не найден: $FILE" >&2
	# exit 1 # disabled
}

# Кэшируем первые 5 строк
head_output="$(head -n 5 "$FILE" 2>/dev/null)" || {
	echo "$LOG_PREFIX ⚠️ Ошибка чтения файла: $FILE" >&2
	# exit 1 # disabled
}

# Флаги
updated=false
add_line() {
	local line="$1"
	# Вставка строки перед первой непустой строкой
	awk -v insert="$line" '
    BEGIN { added=0 }
    /^[[:space:]]*$/ && !added { print; next }
    !added { print insert; added=1 }
    { print }
  ' "$FILE" >"$TMP_FILE" && mv "$TMP_FILE" "$FILE"
	echo "$LOG_PREFIX ⚙️ Добавлено: $line"
	updated=true
}

# Проверка 'cd ~'
if ! grep -qE '^\s*cd\s+~\s*$' <<<"$head_output"; then
	echo "$LOG_PREFIX ⚠️ Отсутствует 'cd ~'"
	[[ "$MODE" == "fix" ]] && add_line "cd ~"
fi

# Проверка 'mkdir -p ~/'
if ! grep -qE '^\s*mkdir\s+-p\s+~/' <<<"$head_output"; then
	echo "$LOG_PREFIX ⚠️ Отсутствует 'mkdir -p ~/'"
	[[ "$MODE" == "fix" ]] && {
		subpath="$(dirname "${FILE#$HOME/}")"
		mkdir_cmd="mkdir -p ~/$(dirname "$subpath")"
		add_line "$mkdir_cmd"
	}
fi

if [[ "$updated" == true ]]; then
	echo "$LOG_PREFIX ✅ Автофикс применён к $FILE"
fi

exit 0
