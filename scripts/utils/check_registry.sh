#!/data/data/com.termux/files/usr/bin/bash
#!/usr/bin/env bash
# Проверка YAML-реестра объектов WheelZone
# Version: 1.3.0 (production-ready)

set -o errexit -o nounset -o pipefail
export LC_ALL=C

# Конфигурация
REGISTRY="$HOME/wz-wiki/docs/registry/servers/registry.yaml"
BASE="$HOME/wz-wiki/"
MAX_SLUG_LENGTH=255
MAX_PATH_LENGTH=4096
LOG_FILE="/var/log/wz_registry_check.log"
MAX_LOG_SIZE_MB=10

# Инициализация
declare -A UUIDS SLUGS PATHS SHA_CACHE
ERROR_COUNT=0
START_TIME=$(date +%s)

# Функции
format_duration() {
  local seconds=$1
  printf "%02d:%02d:%02d" $((seconds/3600)) $((seconds%3600/60)) $((seconds%60))
}

check_dependency() {
  if ! command -v "$1" >/dev/null; then
    echo "❌ Требуется $1" >&2
    exit 1
  fi
}

setup_logging() {
  if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="/tmp/wz_registry_check-$(date +%F-%T).log"
    echo "ℹ️ Используется временный лог: $LOG_FILE" >&2
  fi
  exec 2> >(tee -a "$LOG_FILE" >&2)
}

# Основной скрипт
echo "=== Проверка реестра: $REGISTRY ===" >&2
setup_logging

# Проверка зависимостей и файлов
for cmd in yq realpath sha256sum; do
  check_dependency "$cmd"
done

if [[ ! -f "$REGISTRY" || ! -r "$REGISTRY" ]]; then
  echo "❌ Файл реестра недоступен" >&2
  exit 1
fi

# Чтение и проверка YAML
items_count=$(yq eval '. | length' "$REGISTRY") || {
  echo "❌ Ошибка чтения YAML" >&2
  exit 1
}

[[ $items_count -eq 0 ]] && { echo "❌ Реестр пуст" >&2; exit 1; }

# Проверка элементов
for ((i = 0; i < items_count; i++)); do
  read -r uuid slug path sha < <(
    yq eval ".[$i] | [.uuid, .slug, .path, .sha256] | join(\" \")" "$REGISTRY"
  ) || { echo "❌ [$i] Ошибка чтения"; ((ERROR_COUNT++)); continue; }

  # Проверка полей и файлов
  [[ -z "$uuid" ]] && { echo "❌ [$i] Пустой UUID"; ((ERROR_COUNT++)); }
  [[ ! "$slug" =~ ^[a-z0-9_-]+$ ]] && { echo "❌ [$i] Неверный slug"; ((ERROR_COUNT++)); }
  
  fullpath=$(realpath -m -- "$BASE/$path") || { 
    echo "❌ [$i] Недопустимый path"; ((ERROR_COUNT++)); continue; 
  }

  # Проверка SHA256
  if [[ -n "${SHA_CACHE[$fullpath]}" ]]; then
    calc_sha="${SHA_CACHE[$fullpath]}"
  else
    calc_sha=$(sha256sum -- "$fullpath" | awk '{print $1}') || {
      echo "❌ [$i] Ошибка SHA256"; ((ERROR_COUNT++)); continue;
    }
    SHA_CACHE[$fullpath]="$calc_sha"
  fi

  [[ "$sha" != "$calc_sha" ]] && { 
    echo "❌ [$i] Несовпадение SHA256"; ((ERROR_COUNT++)); 
  }
done

# Итог
RUNTIME=$(format_duration $(( $(date +%s) - START_TIME )))
if [[ $ERROR_COUNT -gt 0 ]]; then
  echo "❌ Проверка завершена с $ERROR_COUNT ошибками за $RUNTIME" >&2
  exit 1
else
  echo "✅ Проверка успешно завершена за $RUNTIME" >&2
  exit 0
fi
