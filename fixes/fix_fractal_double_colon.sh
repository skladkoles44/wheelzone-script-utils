#!/data/data/com.termux/files/usr/bin/bash
# 🚑 Финальный FIX: устраняет двойное двоеточие FRACTAL::/...

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

# Удаляем старые строки обработки FRACTAL
sed -i '/match=/d' "$TARGET"
sed -i '/nested_input=/d' "$TARGET"

# Вставляем нормальный блок (устраняет :: и нормализует путь)
sed -i '/if \[\[ "\$line" =~ FRACTAL:.* \]\]; then/a\
  match="${BASH_REMATCH[0]}"\n\
  nested_input="${match#FRACTAL}"\n\
  nested_input="${nested_input##:}"\n\
  nested_input="${nested_input/#\\~/$HOME}"\n\
  nested_input="$(realpath -m \"$nested_input\" 2>/dev/null || echo \"$nested_input\")"
' "$TARGET"

echo "✅ Ультимативный фикс применён: двойное двоеточие устранено"
