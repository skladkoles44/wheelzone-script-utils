#!/data/data/com.termux/files/usr/bin/bash
# 🚑 Форс-фикс для FRACTAL match-пути

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

# Удаляем все старые строки nested_input=
sed -i '/nested_input=/d' "$TARGET"

# Добавляем надёжный код после строки с BASH_REMATCH
sed -i '/BASH_REMATCH\[0\]/a\
nested_input="${match#FRACTAL:}"\n\
nested_input="${nested_input#:}"\n\
nested_input="${nested_input/#\\~/$HOME}"\n\
nested_input=\"$(realpath -m \\\"$nested_input\\\" 2>/dev/null || echo \\\"$nested_input\\\")\"' "$TARGET"

echo "✅ Форс-фикс применён: путь очищается и нормализуется"
