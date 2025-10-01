#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$HOME/wheelzone-script-utils"
FILE="$REPO/configs/patterns.yaml"
LOGDIR="$HOME/wzbuffer/logs"
LOGFILE="$LOGDIR/patterns.log"

mkdir -p "$LOGDIR"

# Проверка наличия файла
if [[ ! -f "$FILE" ]]; then
  echo "❌ patterns.yaml не найден по пути: $FILE"
  exit 1
fi

# Чтение паттерна из stdin
echo "👉 Вставь блок паттерна (PAT-XXX), затем Ctrl+D:"
NEW_BLOCK=$(cat)

if [[ -z "$NEW_BLOCK" ]]; then
  echo "❌ Пустой ввод. Нечего добавлять."
  exit 1
fi

# Добавление в файл
echo "$NEW_BLOCK" >> "$FILE"

# Контрольная сумма md5
HASH=$(md5sum "$FILE" | awk '{print $1}')
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "✅ Паттерн добавлен. Новый md5: $HASH"

# Логирование
echo "$TS | $HASH | added pattern block" >> "$LOGFILE"

# Git commit + push
cd "$REPO"
git add "$FILE"
git commit -m "patterns.yaml: update ($HASH)"
git push
