#!/bin/bash
# sanitize_csv_encoding.sh v2 — поддержка UTF-16 и BOM
INPUT="$1"
OUT="${INPUT%.csv}_clean.csv"

if [ ! -f "$INPUT" ]; then
  echo "❌ Файл не найден: $INPUT" >&2
  exit 1
fi

# Попробуем определить кодировку (если есть 'file' — опционально)
ENC=$(file -bi "$INPUT" 2>/dev/null | cut -d= -f2)
[ -z "$ENC" ] && ENC="utf-16"

# Пробуем сконвертировать в UTF-8 из UTF-16 или указанной кодировки
if iconv -f "$ENC" -t utf-8 "$INPUT" > "$OUT" 2>/dev/null; then
  echo "✅ Конвертирован из $ENC в UTF-8: $OUT"
else
  echo "⚠️ Не удалось определить кодировку, пробуем UTF-16LE → UTF-8"
  iconv -f UTF-16LE -t UTF-8 "$INPUT" > "$OUT" 2>/dev/null || {
    echo "❌ Ошибка iconv" >&2
    exit 1
  }
fi

# Удалим неASCII символы, кроме стандартных
sed -i 's/[^[:print:],;._@{}()\[\]<>-]/ /g' "$OUT"

echo "📎 Предпросмотр:"
head -n 2 "$OUT" | cat -v
