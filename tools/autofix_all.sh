#!/data/data/com.termux/files/usr/bin/bash
# tools/autofix_all.sh — локальное автоформатирование (shfmt, black, isort)

set -euo pipefail

echo "🧼 [AutoFix] Запуск автоформатирования скриптов..."

# Проверка зависимостей
command -v black >/dev/null || pip install black
command -v isort >/dev/null || pip install isort
command -v shfmt >/dev/null || {
  curl -sL https://github.com/mvdan/sh/releases/download/v3.7.0/shfmt_v3.7.0_linux_amd64 \
    -o "$PREFIX/bin/shfmt" && chmod +x "$PREFIX/bin/shfmt"
}

# Форматирование Bash
echo "🔧 [shfmt] Форматирование *.sh"
find scripts/ -name "*.sh" -exec shfmt -w -i 2 -ci -s {} +

# Форматирование Python
echo "🔧 [black] Форматирование *.py"
black scripts/

echo "🔧 [isort] Сортировка импортов"
isort scripts/

# Добавление прав
echo "🔒 [chmod +x] Назначение прав исполняемости"
find scripts/ -name "*.sh" -o -name "*.py" -exec chmod +x {} +

echo "✅ [AutoFix] Завершено успешно"
