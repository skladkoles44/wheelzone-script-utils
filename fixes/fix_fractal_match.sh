#!/data/data/com.termux/files/usr/bin/bash
# 🛠 Полный фикс match/FRACTAL парсинга

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

# Проверим наличие проблемного шаблона
if grep -q 'nested_input=' "$TARGET"; then
  sed -i '/nested_input=/c\
match="${BASH_REMATCH[0]}"\
nested_input="${match#FRACTAL:}"\
nested_input="${nested_input#:}"\
nested_input="${nested_input/#\\~/$HOME}"' "$TARGET"
  echo "✅ Фикс применён: нормализован FRACTAL match"
else
  echo "✅ Фикс не требуется"
fi
