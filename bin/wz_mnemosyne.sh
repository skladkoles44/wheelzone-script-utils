#!/data/data/com.termux/files/usr/bin/bash
# WheelZone CLI — Mnemosyne Reader

FILE="$HOME/wz-wiki/mnemosyne/mnemosyne_index.yaml"

if [[ ! -f "$FILE" ]]; then
  echo "❌ Mnemosyne index не найден: $FILE"
  exit 1
fi

echo "🧠 Осознанные моменты:"
awk '/^- uuid:/,/^$/' "$FILE" | sed 's/^- uuid:/\n🔹 UUID:/;s/^  /  /'
