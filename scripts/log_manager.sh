#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:27+03:00-1068883908
# title: log_manager.sh
# component: .
# updated_at: 2025-08-26T13:19:27+03:00

# 🗂 log_manager.sh v3.2 — HyperOS Optimized

# --help / --version
if [[ "$1" == "--help" ]]; then
  echo "🧾 log_manager.sh v3.2 — Утилита архивации логов"
  echo
  echo "Использование:"
  echo "  bash log_manager.sh [--help] [--version]"
  echo
  echo "Описание:"
  echo "  - Архивирует ndjson-логи"
  echo "  - Удаляет старые архивы (>7 дней)"
  echo "  - Использует lock-файл для защиты от параллельного запуска"
  echo "  - Поддерживает Termux и Linux"
  echo
  echo "Переменные окружения:"
  echo "  LOG_SOURCE, LOG_DEST, SYNC_LOG, LOCK_FILE"
  exit 0
fi

if [[ "$1" == "--version" ]]; then
  echo "log_manager.sh v3.2"
  exit 0
fi

# ==== Параметры ====
LOG_SOURCE="${LOG_SOURCE:-$HOME/.wzlogs}"
LOG_DEST="${LOG_DEST:-$HOME/.wzlogs/archive}"
SYNC_LOG="${SYNC_LOG:-$HOME/.wzlogs/log_manager_sync.log}"
LOCK_FILE="${LOCK_FILE:-$HOME/.wz_atomic/wz_log_manager.lock}"
DAYS_TO_KEEP=7

# ==== Подготовка ====
mkdir -p "$LOG_SOURCE" "$LOG_DEST" "$(dirname "$SYNC_LOG")" "$(dirname "$LOCK_FILE")"

# ==== Блокировка ====
exec 9>"$LOCK_FILE"
flock -n 9 || {
  echo "🔒 log_manager: уже запущен. Выход." >> "$SYNC_LOG"
  exit 1
}

# ==== Архивация ====
echo "📦 Архивация логов: $(date -Is)" >> "$SYNC_LOG"
find "$LOG_SOURCE" -maxdepth 1 -name '*.ndjson' | while read -r logfile; do
  [ -s "$logfile" ] || continue
  bname=$(basename "$logfile" .ndjson)
  ts=$(date +%Y%m%d_%H%M%S)
  zipfile="$LOG_DEST/${bname}_$ts.zip"
  zip -j "$zipfile" "$logfile" && rm -f "$logfile"
  echo "✅ Архив: $logfile → $zipfile" >> "$SYNC_LOG"
done

# ==== Очистка старых архивов ====
echo "🧹 Очистка старых архивов > $DAYS_TO_KEEP дней" >> "$SYNC_LOG"
find "$LOG_DEST" -name '*.zip' -type f -mtime +$DAYS_TO_KEEP -exec rm -f {} \;

# ==== Дублирование на VPS (заглушка) ====
echo "📤 Дублирование логов на VPS (заглушка)" >> "$SYNC_LOG"
# scp или rsync можно будет добавить позже

echo "✅ Готово: $(date -Is)" >> "$SYNC_LOG"
