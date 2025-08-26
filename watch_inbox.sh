#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:17+03:00-2025310506
# title: watch_inbox.sh
# component: .
# updated_at: 2025-08-26T13:20:17+03:00

export PATH=/data/data/com.termux/files/usr/bin:$PATH

INBOX=~/storage/downloads
DEST=~/wheelzone/bootstrap_tool
LOG=~/wheelzone/bootstrap_tool/git_push_log.md

# Обработка только файлов, начинающихся с WZ_
find "$INBOX" -type f -name 'WZ_*' | while read file; do
  fname=$(basename "$file")
  fchat=$(echo "$fname" | cut -d'_' -f2)
  ftarget="$DEST/$fchat"

  # Создать папку, если нет
  mkdir -p "$ftarget"

  # Проверка и переименование при конфликте
  if [ -f "$ftarget/$fname" ]; then
    ext="${fname##*.}"
    base="${fname%.*}"
    timestamp=$(date +'%d.%m.%y_%H-%M')
    newname="${base}_${timestamp}_${fchat}.${ext}"
    echo "Файл уже существует. Переименован в: $newname"
  else
    newname="$fname"
  fi

  # Переместить
  mv "$file" "$ftarget/$newname"

  # Проверка на пустоту
  size=$(stat -c%s "$ftarget/$newname")
  [ "$size" -lt 10 ] && echo "Пропущен пустой файл: $newname" && continue

  # Хеш
  sha=$(sha256sum "$ftarget/$newname" | awk '{print $1}')

  # Git
  cd "$DEST"
  git add "$fchat/$newname"
  git commit -m "AutoPush: $newname from inbox"
  git push origin main

  # Лог
  echo "$(date +'%Y-%m-%d %H:%M') | $fchat/$newname | $size bytes | $sha" >> "$LOG"
done
