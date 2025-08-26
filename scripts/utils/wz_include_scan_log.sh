#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:43+03:00-717571804
# title: wz_include_scan_log.sh
# component: .
# updated_at: 2025-08-26T13:19:43+03:00

# WZ Include Scanner v1.0 — без патчинга оригинала, логируем аномалии ':/' ':~' ':$HOME'
set -Eeuo pipefail
FRAC_LOG="$HOME/.wz_logs/fractal_chatend.log"
mkdir -p "$(dirname "$FRAC_LOG")"

ts(){ date -u +'%Y-%m-%d %H:%M:%S'; }
log(){ echo "[$(ts)] $*" >> "$FRAC_LOG"; }

scan_file(){
  local in="$1"
  [ -f "$in" ] || { log "⚠️ input missing: $in"; return 0; }
  # фрактальный префикс
  echo "[${PPID}_${RANDOM}] ↳ 🌿 Запуск фрактальной обработки файла: $in" >> "$FRAC_LOG"

  # Читаем Include-линии
  while IFS= read -r line; do
    case "$line" in
      Include:*) ;;
      *) continue;;
    esac
    # raw после "Include:"
    local raw="${line#Include:}"
    raw="${raw#"${raw%%[![:space:]]*}"}"   # trim leading spaces

    # Ловим аномалии ровно по сырому значению (как в старых логах)
    if echo "$raw" | grep -Eq '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME'; then
      echo "[${PPID}_${RANDOM}] ↳ ⚠️ Не найден файл: $raw" >> "$FRAC_LOG"
      continue
    fi

    # Санитайз (безопасный минимум)
    local sane="$raw"
    sane="${sane#:}"                    # убрать ведущий ':'
    case "$sane" in
      "~"|"~/") sane="$HOME/";;
      "~"/*)    sane="$HOME/${sane#~/}";;
    esac
    # $HOME-экспансия
    sane="$(echo "$sane" | sed "s#^\$HOME#$HOME#")"

    # Проверка наличия файла
    if [ -f "$sane" ]; then
      echo "[${PPID}_${RANDOM}] ↳ ✅ Include OK: $raw → $sane" >> "$FRAC_LOG"
    else
      # Логируем факт отсутствия
      echo "[${PPID}_${RANDOM}] ↳ ⚠️ Не найден файл: $raw" >> "$FRAC_LOG"
    fi
  done < "$in"
}

for f in "$@"; do
  scan_file "$f"
done
