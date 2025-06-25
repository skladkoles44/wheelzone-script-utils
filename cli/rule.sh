#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

RULES_DIR="${HOME}/wz-knowledge/rules"
EDITOR="${EDITOR:-nano}"

check_rules_dir() {
  [[ -d "$RULES_DIR" ]] || { echo "❌ Директория $RULES_DIR не существует" >&2; exit 1; }
}

show_usage() {
  cat <<EOF_USAGE
📘 WZ Rule CLI — управление правилами WheelZone

Использование:
  $0 list              — список всех правил
  $0 view <UUID>       — просмотр правила
  $0 grep <текст>      — поиск по содержимому
  $0 edit <UUID>       — редактирование правила
EOF_USAGE
  exit 1
}

validate_uuid() {
  [[ -n "${1:-}" ]] || { echo "❌ Укажите UUID" >&2; exit 1; }
  local file="${RULES_DIR}/rule_${1}.md"
  [[ -f "$file" ]] || { echo "❌ Правило rule_${1}.md не найдено" >&2; exit 1; }
}

main() {
  local cmd="${1:-}"; shift || true
  check_rules_dir

  case "$cmd" in
    list)
      find "$RULES_DIR" -maxdepth 1 -name 'rule_*.md' -printf "%f\n" | sed -E 's/^rule_(.*)\.md$/\1/' | sort
      ;;
    view)
      validate_uuid "$1"
      bat --pager=never "${RULES_DIR}/rule_${1}.md"
      ;;
    grep)
      [[ -n "${1:-}" ]] || { echo "❌ Укажите текст для поиска" >&2; exit 1; }
      grep -ri --color=auto "$1" "$RULES_DIR"
      ;;
    edit)
      validate_uuid "$1"
      "$EDITOR" "${RULES_DIR}/rule_${1}.md"
      ;;
    *) show_usage ;;
  esac
}

main "$@"
