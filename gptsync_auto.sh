#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:06+03:00-1993687041
# title: gptsync_auto.sh
# component: .
# updated_at: 2025-08-26T13:20:06+03:00

# Автосинхронизация WheelZone с проверкой SHA256

SRC=~/storage/downloads/project_44/Termux
DST_SCRIPT=~/storage/downloads/project_44/Termux/Script
DST_BACKUP=~/wheelzone/bootstrap_tool/Backup
DST_CORE=~/wheelzone/auto-framework/ALL
DST_HDATA=~/wheelzone/auto-framework/H_data
LOG=~/wheelzone/bootstrap_tool/Logs/synced_files.log
HASHDB=~/.wz_hash_registry.txt

mkdir -p "$DST_SCRIPT" "$DST_BACKUP" "$DST_CORE" "$DST_HDATA" "$(dirname "$LOG")"
touch "$HASHDB"

cd "$SRC" || exit 1

for file in *; do
  [ -f "$file" ] || continue
  hash=$(sha256sum "$file" | awk '{print $1}')
  if grep -q "$hash" "$HASHDB"; then
    echo "Пропущен (уже есть): $file"
    continue
  fi

  ext="${file##*.}"
  base="${file%.*}"
  target="${base}_synced.${ext}"

  case "$ext" in
    sh)   mv -v "$file" "$DST_SCRIPT/$target" ;;
    md|txt) mv -v "$file" "$DST_BACKUP/$target" ;;
    jsonl|log) mv -v "$file" "$DST_HDATA/$target" ;;
    conf|pub) mv -v "$file" "$DST_CORE/$target" ;;
    *) echo "Пропущен (неподдерж.): $file" ;;
  esac

  echo "$hash $file" >> "$HASHDB"
  echo "$(date +%F_%T) - $file -> $target" >> "$LOG"
done
