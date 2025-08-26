#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:49+03:00-2812494714
# title: auto_deploy_WZ.sh
# component: .
# updated_at: 2025-08-26T13:19:49+03:00


# Источники файлов
SOURCES=(
  "/storage/downloads/project_44"
  "/sdcard/project_44"
  "/sdcard/chagpt_upload"
  "/sdcard/downloads"
)

# Целевые директории
DST_SCRIPT=~/storage/downloads/project_44/Termux/Script
DST_BACKUP=~/wheelzone/bootstrap_tool/Backup
DST_CORE=~/wheelzone/auto-framework/ALL
DST_HDATA=~/wheelzone/auto-framework/H_data
LOG=~/wheelzone/bootstrap_tool/Logs/deploy_log.jsonl
INDEX=~/wheelzone/bootstrap_tool/Backup/WZ_Deploy_File_Index.md

mkdir -p "$DST_SCRIPT" "$DST_BACKUP" "$DST_CORE" "$DST_HDATA" "$(dirname "$LOG")"

echo "# WZ Deploy File Index" > "$INDEX"

for SRC in "${SOURCES[@]}"; do
  cd "$SRC" || continue
  for f in $(find . -type f); do
    fname="$(basename "$f")"
    fext="${fname##*.}"
    case "$fext" in
      sh)   cp "$f" "$DST_SCRIPT/$fname" && echo "- $fname → Script" >> "$INDEX" ;;
      md|txt) cp "$f" "$DST_BACKUP/$fname" && echo "- $fname → Backup" >> "$INDEX" ;;
      jsonl|log) cp "$f" "$DST_HDATA/$fname" && echo "- $fname → H_data" >> "$INDEX" ;;
      conf|pub) cp "$f" "$DST_CORE/$fname" && echo "- $fname → ALL" >> "$INDEX" ;;
      *) echo "Пропущен: $f" >> "$LOG" ;;
    esac
    echo "$(date +%F_%T) - $SRC/$f" >> "$LOG"
  done
done

echo "DEPLOY: $(date +%F_%T)" > ~/wheelzone/bootstrap_tool/Backup/WZ_DEPLOY_SUCCESS.flag