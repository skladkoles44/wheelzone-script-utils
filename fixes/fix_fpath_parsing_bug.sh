#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:08+03:00-3480579595
# title: fix_fpath_parsing_bug.sh
# component: .
# updated_at: 2025-08-26T13:19:08+03:00

# 🔧 Автофикс бага :/path в wz_chatend.sh

TARGET="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"

if grep -q 'nested_file=":' "$TARGET"; then
  sed -i 's|nested_file=":|nested_file="|' "$TARGET"
  echo "✅ Фикс применён: удалено двоеточие в path-парсинге"
else
  echo "✅ Фикс не требуется: код уже обновлён"
fi
