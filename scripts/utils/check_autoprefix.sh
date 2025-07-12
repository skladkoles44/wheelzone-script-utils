#!/bin/bash
# WZ Check: rule-autoprefix-paths — гибрид v2.0 (WBP)

set -euo pipefail

readonly FILE="${1:?❌ Укажите путь к файлу для проверки}"

[[ -f "$FILE" ]] || {
  echo "❌ Файл '$FILE' не найден" >&2
  exit 1
}

head_output="$(head -n 5 "$FILE")"

# Проверка cd ~
echo "$head_output" | grep -qE '^\s*cd\s+~\s*$' || {
  echo "⚠️  Нет 'cd ~' в первых строках файла $FILE"
  echo "$head_output" | sed 's/^/  | /'
  exit 2
}

# Проверка mkdir -p ~/
echo "$head_output" | grep -qE '^\s*mkdir\s+-p\s+~/' || {
  echo "⚠️  Нет 'mkdir -p ~/' в первых строках файла $FILE"
  echo "$head_output" | sed 's/^/  | /'
  exit 3
}

exit 0
