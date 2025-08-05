#!/data/data/com.termux/files/usr/bin/bash
# 🔧 Автофикс бага :/path в wz_chatend.sh

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

if grep -q 'nested_file=":' "$TARGET"; then
  sed -i 's|nested_file=":|nested_file="|' "$TARGET"
  echo "✅ Фикс применён: удалено двоеточие в path-парсинге"
else
  echo "✅ Фикс не требуется: код уже обновлён"
fi
