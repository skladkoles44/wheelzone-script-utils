#!/data/data/com.termux/files/usr/bin/bash
# ✅ Финальный фикс обработки FRACTAL путей

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

# Удаляем старые строки, связанные с nested_input=
sed -i '/nested_input=/d' "$TARGET"
sed -i '/match=/d' "$TARGET"

# Вставляем новый блок после строки: if [[ "$line" =~ FRACTAL:.* ]]; then
sed -i '/if \[\[ "\$line" =~ FRACTAL:.* \]\]; then/a\
  match="${BASH_REMATCH[0]}"\n\
  nested_input="${match#FRACTAL:}"\n\
  nested_input="${nested_input#:}"\n\
  nested_input="${nested_input/#\\~/$HOME}"\n\
  nested_input="$(realpath -m \"$nested_input\" 2>/dev/null || echo \"$nested_input\")"
' "$TARGET"

echo "✅ Финальный фикс применён: обработка FRACTAL нормализована"
