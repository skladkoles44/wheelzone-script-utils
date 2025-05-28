#!/data/data/com.termux/files/usr/bin/bash

# Проверка строки на скрытые/непечатаемые символы
check_string_clean() {
  local input="$1"
  echo -n "$input" | grep -P "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\xA0\xAD\xE0-\xF8\xFE\xFF\xEF\xBB\xBF]" >/dev/null
  if [ $? -eq 0 ]; then
    echo "[!] Обнаружены скрытые или спецсимволы"
    echo "$input" | xxd
    return 1
  else
    echo "[✓] Строка чиста (только ASCII)"
    return 0
  fi
}

check_string_clean "$1"
