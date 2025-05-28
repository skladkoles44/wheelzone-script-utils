#!/data/data/com.termux/files/usr/bin/bash
# Автосинхронизация файлов из Termux в систему WheelZone

SRC=~/storage/downloads/project_44/Termux
DST_SCRIPT=~/storage/downloads/project_44/Termux/Script
DST_BACKUP=~/wheelzone/bootstrap_tool/Backup
DST_CORE=~/wheelzone/auto-framework/ALL
DST_HDATA=~/wheelzone/auto-framework/H_data
LOG=~/wheelzone/bootstrap_tool/Logs/synced_files.log

mkdir -p "$DST_SCRIPT" "$DST_BACKUP" "$DST_CORE" "$DST_HDATA" "$(dirname "$LOG")"

cd "$SRC" || exit 1

for file in *; do
  [ -f "$file" ] || continue
  ext="${file##*.}"
  base="${file%.*}"
  target="${base}_synced.${ext}"

  case "$ext" in
    sh)   mv -v "$file" "$DST_SCRIPT/$target" ;;
    md|txt) mv -v "$file" "$DST_BACKUP/$target" ;;
    jsonl|log) mv -v "$file" "$DST_HDATA/$target" ;;
    conf|pub) mv -v "$file" "$DST_CORE/$target" ;;
    *) echo "Пропущен: $file" ;;
  esac

  echo "$(date +%F_%T) - $file -> $target" >> "$LOG"
done