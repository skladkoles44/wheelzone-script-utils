#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# == Context ==
# [Termux] Коллектор токенов из аудита → ревью-файл → по подтверждению создаёт ~/.env.wzbot и зашифрованную копию.
# Новые термины: GPG (шифрование файла), idempotent (безопасно повторять), PEM (текстовый ключ).

AUDIT="${AUDIT_PATH:-/data/data/com.termux/files/home/wzbuffer/search_rclone_gdrive_audit.txt}"
WZBUF="$HOME/wzbuffer"
TOKENS_REVIEW="$WZBUF/tokens_found_for_review.txt"
ENV_PLAIN="$HOME/.env.wzbot"
ENV_GPG="$WZBUF/.env.wzbot.gpg"
TMP_RAW="$WZBUF/.tokens_raw.txt"
TMP_EXTRACT="$WZBUF/.tokens_extract.txt"

log()  { printf '%s %s\n' "[wz_env_collect]" "$*"; }
warn() { printf '%s %s\n' "[wz_env_collect][WARN]" "$*" >&2; }
die()  { printf '%s %s\n' "[wz_env_collect][ERROR]" "$*" >&2; exit 1; }

mkdir -p "$WZBUF"

# 0) Входной аудит-файл
[ -s "$AUDIT" ] || die "Аудит не найден или пуст: $AUDIT"

# 1) Сбор совпадений (POSIX ERE, без ленивых квантификаторов)
#    — OAuth: refresh_token, access_token, client_secret/client_id
#    — JSON ключи: "private_key": "....", "client_secret": "...."
#    — PEM: BEGIN (RSA )?PRIVATE KEY
#    — JWT: eyJ..... (типичный префикс JWT)
: > "$TMP_RAW"

# Ключ-значение в строке
grep -Eio 'refresh_token=([^[:space:]]+)' "$AUDIT"        >> "$TMP_RAW" || true
grep -Eio 'access_token=([^[:space:]]+)'  "$AUDIT"        >> "$TMP_RAW" || true
grep -Eio 'client_secret[=:]"?[^[:space:]",]+' "$AUDIT"   >> "$TMP_RAW" || true
grep -Eio 'client_id[=:]"?[^[:space:]",]+'    "$AUDIT"    >> "$TMP_RAW" || true

# JSON-пары
grep -Eio '"client_secret"[[:space:]]*:[[:space:]]*"[^"]+' "$AUDIT" >> "$TMP_RAW" || true
grep -Eio '"private_key"[[:space:]]*:[[:space:]]*"[^"]+'   "$AUDIT" >> "$TMP_RAW" || true
grep -Eio '"type"[[:space:]]*:[[:space:]]*"service_account"' "$AUDIT" >> "$TMP_RAW" || true

# PEM-заголовки и JWT
grep -Eio 'BEGIN( RSA)? PRIVATE KEY' "$AUDIT"              >> "$TMP_RAW" || true
grep -Eio '\beyJ[A-Za-z0-9._-]{10,}\b' "$AUDIT"            >> "$TMP_RAW" || true

# 2) Очистка и нормализация
#    делаем список уникальных кандидатов (ещё не .env)
awk 'NF>0' "$TMP_RAW" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | sort -u > "$TMP_EXTRACT"

# 3) Подготовка файла ревью
: > "$TOKENS_REVIEW"
{
  echo "# WheelZone — токены, найденные в аудите"
  echo "# Источник: $AUDIT"
  echo "# Инструкция: проверь, отредактируй имена переменных слева от '=', удали ложные совпадения."
  echo "# Формат: VAR_NAME=VALUE"
  echo
} >> "$TOKENS_REVIEW"

count=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  # Выделение значения (после '=', ':' или после JSON-ключа)
  val="$line"
  case "$line" in
    BEGIN*"PRIVATE KEY"*)
      # Оставляем как есть — это маркер, не сам ключ
      val="$line"
      ;;
    *:*|*='*')
      val="$(printf '%s' "$line" | sed -E 's/^[^=:\"]+[=:\"]//')"
      ;;
    *)
      val="$line"
      ;;
  esac

  # Хеш для предложения имени
  hash="$(printf '%s' "$val" | sha256sum | awk '{print substr($1,1,8)}')"
  key="WZ_TOKEN_${hash}"
  printf '%s=%s\n' "$key" "$val" >> "$TOKENS_REVIEW"
  count=$((count+1))
done < "$TMP_EXTRACT"

chmod 600 "$TOKENS_REVIEW" || true
log "Найдено кандидатов: $count"
log "Файл ревью: $TOKENS_REVIEW"
log "Открой, переименуй ключи (слева) и удали лишнее. Затем запусти: $0 --apply"

# 4) Применение: создание ~/.env.wzbot и зашифрованной копии
if [ "${1-}" = "--apply" ]; then
  # Проверка формата KEY=VALUE
  if ! grep -Eq '^[A-Za-z_][A-Za-z0-9_]*=.+$' "$TOKENS_REVIEW"; then
    die "В $TOKENS_REVIEW нет строк формата KEY=VALUE. Отредактируй файл."
  fi

  # Создание .env с заголовком (WZ Artifact Header v1.0)
  umask 177
  cat > "$ENV_PLAIN" <<'EOF_ENV'
# WZ Artifact Header v1.0
# Registry: wheelzone://secrets/env/wzbot/v0
# Fractal-UUID: PENDING-UUID
# Task-Class: idempotent
# Version: v0.1.0
# Owner: WheelZone
# Maintainer: wheelzone-script-utils
# Created-At: PENDING
# Updated-At: PENDING
# Idempotency: Yes
# Side-Effects: creates local plaintext env + optional encrypted copy
# Integrity-Hash: PENDING
# NOTE: Не синхронизировать plaintext в облако.

EOF_ENV

  # Добавляем валидные пары
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=.+$' "$TOKENS_REVIEW" >> "$ENV_PLAIN" || true
  chmod 600 "$ENV_PLAIN"

  # Хэш целостности (sha256)
  hash_env="$(sha256sum "$ENV_PLAIN" | awk '{print $1}')"
  printf '# Integrity-Hash: %s\n' "$hash_env" >> "$ENV_PLAIN"

  log "Создан файл: $ENV_PLAIN (mode 600)"

  # Опциональная зашифрованная копия (если установлен gpg)
  if command -v gpg >/dev/null 2>&1; then
    # В интерактиве gpg спросит пароль; без пароля создание отменится.
    gpg --symmetric --cipher-algo AES256 --output "$ENV_GPG" "$ENV_PLAIN" || warn "GPG: шифрование отменено или ошибка"
    [ -f "$ENV_GPG" ] && chmod 600 "$ENV_GPG" && log "Зашифрованная копия: $ENV_GPG"
  else
    warn "gpg не найден. Установи: pkg install gnupg (шифрование файла)."
  fi

  log "Готово. Экспорт переменных для текущей сессии: set -a; . \"$ENV_PLAIN\"; set +a"
fi

# 5) Очистка временных
rm -f "$TMP_RAW" "$TMP_EXTRACT" 2>/dev/null || true
