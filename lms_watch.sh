#!/data/data/com.termux/files/usr/bin/bash
# lms_watch.sh — фоновый обработчик новых digest-уроков для /шеф

# Пути
SHEF_DIR="$HOME/wheelzone/wheelzone-core/personas/shef"
KNOW_DIR="$SHEF_DIR/roadmap/knowledge"
LMS_LOG="$KNOW_DIR/lms_log.jsonl"
EVOL_MAP="$SHEF_DIR/roadmap/evolution_map.md"

# Убедимся, что есть лог
touch "$LMS_LOG"
touch "$EVOL_MAP"

# Для каждого digest-файла
for FILE in "$SHEF_DIR"/digest_*.md; do
  DATE=$(basename "$FILE" | sed -E 's/digest_([0-9-]+)\.md/***REMOVED***/')
  # Проверяем, нет ли уже урока в lms_log
  if ! grep -q "\"date\":\"$DATE\"" "$LMS_LOG"; then
    # Вытаскиваем первую строку после заголовка для урока
    SUMMARY=$(grep -m1 "^##" "$FILE" | sed 's/^## //')
    # Генерируем ID урока
    UID=$(echo "$DATE$SUMMARY" | sha1sum | cut -c1-6 | tr a-z A-Z)
    LESSON_ID="L${UID}"
    # Формируем JSON урока
    LESSON_JSON=$(jq -n \
      --arg id "$LESSON_ID" \
      --arg date "$DATE" \
      --arg title "$SUMMARY" \
      --arg type "digest" \
      --arg source "$(basename "$FILE")" \
      '{id: $id, date: $date, title: $title, type: $type, source: $source}')
    # Записываем в lms_log
    echo "$LESSON_JSON" >> "$LMS_LOG"
    # Обновляем карту эволюции
    echo "### 🧠 $DATE — Новый урок: $SUMMARY" >> "$EVOL_MAP"
  fi
done#!/data/data/com.termux/files/usr/bin/bash

# [2025-05-28 09:51] Скрипт создан через newscript()
