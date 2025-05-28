#!/data/data/com.termux/files/usr/bin/bash
echo "[wzproof] Проверка на скрытые символы и целостность скриптов..."

TARGET_DIR=~/bin
LOG=~/storage/downloads/project_44/MetaSystem/Logs/wzproof_issues.log
> "$LOG"

FOUND=0

# 1. Проверка скрытых символов Unicode (невидимые, спец. управляющие)
for f in "$TARGET_DIR"/*.sh; do
  if grep -P "[\x{200B}-\x{200F}\x{E000}-\x{F8FF}]" "$f" > /dev/null; then
    echo "[!] Спецсимволы найдены в: $f" | tee -a "$LOG"
    grep -nP "[\x{200B}-\x{200F}\x{E000}-\x{F8FF}]" "$f" >> "$LOG"
    FOUND=1
  fi
done

# 2. Проверка на BOM (Byte Order Mark)
for f in "$TARGET_DIR"/*.sh; do
  head -c 3 "$f" | grep -q $'\xEF\xBB\xBF'
  if [ $? -eq 0 ]; then
    echo "[!] BOM найден в начале файла: $f" | tee -a "$LOG"
    FOUND=1
  fi
done

if [ $FOUND -eq 0 ]; then
  echo "[wzproof] Всё чисто. Спецсимволов и BOM нет." | tee -a "$LOG"
fi
