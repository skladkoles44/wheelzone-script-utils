#!/usr/bin/env bash

# regen-core.sh — Валидация и восстановление core.yaml
# WheelZone Core Validator v1.0.1

CORE="$HOME/wz-wiki/wz-knowledge/core/core.yaml"
BACKUP_DIR="$HOME/wz-wiki/wz-knowledge/core/"
LOG="$HOME/wzbuffer/regen-core.log"

log() {
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] [$1] $2" | tee -a "$LOG"
}

check_dependencies() {
  if ! command -v python3 >/dev/null; then
    log "ERROR" "Требуется python3, но он не найден."
    exit 1
  fi
  if ! python3 -c "import yaml" 2>/dev/null; then
    log "ERROR" "Не установлен модуль pyyaml. Установите: pip install pyyaml"
    exit 1
  fi
}

validate_yaml() {
  local error_msg
  error_msg=$(python3 -c "
import yaml, sys
with open('$1', 'r') as f:
  try:
    yaml.safe_load(f)
    print('VALID')
  except Exception as e:
    print(f'INVALID: {str(e)}')
    sys.exit(1)
" 2>&1)

  if [[ "$error_msg" == "VALID" ]]; then
    return 0
  else
    log "ERROR" "Ошибка в YAML: ${error_msg#INVALID: }"
    return 1
  fi
}

usage() {
  cat <<USAGE
Usage: regen-core.sh [--check|--restore]

Options:
  --check     Проверить core.yaml на валидность
  --restore   Восстановить core.yaml из последнего бэкапа (если он валиден)
  --help      Показать это сообщение

Файлы:
  $CORE        — основной файл ядра
  $BACKUP_DIR  — каталог с бэкапами core_backup_*.yaml
  $LOG         — лог-файл с результатами

Примеры:
  ./regen-core.sh --check
  ./regen-core.sh --restore
USAGE
}

check_dependencies

case "$1" in
  --check)
    if [[ ! -f "$CORE" ]]; then
      log "ERROR" "Файл $CORE не найден."
      exit 1
    fi
    if validate_yaml "$CORE"; then
      log "INFO" "core.yaml валиден."
    else
      exit 1
    fi
    ;;
  --restore)
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/core_backup_*.yaml 2>/dev/null | head -n1)
    if [[ -z "$LATEST_BACKUP" ]]; then
      log "ERROR" "Бэкапы не найдены в $BACKUP_DIR."
      exit 1
    fi
    if ! validate_yaml "$LATEST_BACKUP"; then
      exit 1
    fi
    if [[ ! -w "$CORE" ]] && [[ -f "$CORE" ]]; then
      log "ERROR" "Нет прав на запись в $CORE."
      exit 1
    fi
    cp "$LATEST_BACKUP" "$CORE"
    log "INFO" "Восстановлен из бэкапа: $LATEST_BACKUP"
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
