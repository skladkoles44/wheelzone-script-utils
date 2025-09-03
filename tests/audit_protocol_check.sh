#!/usr/bin/env bash
# WZ CI Check: audit_protocol_check.sh
# Purpose: Проверка наличия и валидности Omega Ultra Audit Protocol в wz-wiki
# Strict mode
set -Eeuo pipefail
IFS=$'\n\t'
LC_ALL=C.UTF-8

# --- Config ---
WIKI_DIR="${WIKI_DIR:-$HOME/wz-wiki}"
TARGET_REL="docs/security/omega_ultra_audit_protocol.md"
TARGET="$WIKI_DIR/$TARGET_REL"

log()   { printf '[WZ][AUDIT] %s\n' "$*"; }
fail()  { printf '[WZ][AUDIT][FAIL] %s\n' "$*" >&2; exit 1; }
warn()  { printf '[WZ][AUDIT][WARN] %s\n' "$*" >&2; }

# --- 1) File existence ---
[ -d "$WIKI_DIR" ] || fail "Не найден WIKI_DIR: $WIKI_DIR"
[ -f "$TARGET" ]   || fail "Нет файла протокола: $TARGET_REL"

log "Файл найден: $TARGET_REL"

# --- 2) fractal_uuid первой непустой строкой ---
first_non_empty="$(awk 'NF{print; exit}' "$TARGET")"
if [[ ! "$first_non_empty" =~ ^fractal_uuid:\ [0-9a-fA-F-]{36}$ ]]; then
  fail "Первая непустая строка НЕ fractal_uuid: '$first_non_empty'"
fi

fractal_uuid="${first_non_empty#fractal_uuid: }"
# UUID v4 формат (слабая проверка — допускаем любые 36-символьные UUID)
if ! grep -qiE '^[0-9a-f-]{36}$' <<<"$fractal_uuid"; then
  fail "Некорректный формат fractal_uuid: $fractal_uuid"
fi
log "fractal_uuid ок: $fractal_uuid"

# --- 3) Parse YAML front matter ---
# Извлекаем блок между первой и второй строкой '---'
yaml="$(awk '
  /^---$/ {c++; next}
  c==1 {print}
  c>1 {exit}
' "$TARGET")"

[ -n "$yaml" ] || fail "YAML фронтматтер не найден между --- ---"

# Поля: uuid, version, status
yaml_uuid="$(grep -E '^uuid:' <<<"$yaml" | head -n1 | sed -E 's/^uuid:[[:space:]]*//')"
yaml_version="$(grep -E '^version:' <<<"$yaml" | head -n1 | sed -E 's/^version:[[:space:]]*//')"
yaml_status="$(grep -E '^status:' <<<"$yaml" | head -n1 | sed -E 's/^status:[[:space:]]*//')"

[ -n "${yaml_uuid:-}" ]    || fail "В YAML нет поля uuid:"
[ -n "${yaml_version:-}" ] || fail "В YAML нет поля version:"
[ -n "${yaml_status:-}" ]  || fail "В YAML нет поля status:"

# Простая валидация форматов
grep -qiE '^[0-9a-f-]{36}$' <<<"$yaml_uuid"    || fail "uuid в YAML не похож на UUID: $yaml_uuid"
grep -qE  '^[0-9]+\.[0-9]+\.[0-9]+$' <<<"$yaml_version" || fail "version не SemVer: $yaml_version"

# Требуем статус PUSHED (по WZ-канонам)
if [[ "$yaml_status" != "PUSHED" ]]; then
  fail "status в YAML должен быть 'PUSHED', сейчас: $yaml_status"
fi

log "YAML фронтматтер ок: uuid=$yaml_uuid version=$yaml_version status=$yaml_status"

# --- 4) Инварианты и мягкие проверки ---
# (Не делаем жёстким требование равенства fractal_uuid и yaml_uuid — они могут быть разными по политике документа/артефакта)
if [[ "$fractal_uuid" != "$yaml_uuid" ]]; then
  warn "fractal_uuid != YAML uuid (это допустимо, но проверь политику соответствия)."
else
  log "fractal_uuid совпадает с YAML uuid."
fi

# --- 5) Отчёт ---
log "OK: Протокол валиден и соответствует базовым инвариантам."
