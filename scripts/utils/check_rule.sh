#!/usr/bin/env bash
# WheelZone :: check_rule.sh
# v2.0 — строгая валидация фронт-маттера:
#   required: uuid, fractal_uuid, slug, type, created_at, content_md5
#   формат: UUIDv4, slug ^[a-z0-9-]+$, type из whitelist, created_at ISO-8601 Z, content_md5 = 32 hex
# Опции: --file <path> (можно несколько), --auto (попробовать автоисправить через wz-preproc augment), --json (только JSON-вывод)
set -Eeuo pipefail
IFS=$'\n\t'

REQ_KEYS="uuid,fractal_uuid,slug,type,created_at,content_md5"
TYPE_WHITELIST="script-bash|script-python|document-md|document-yaml|document-text|artifact"

# --- утилиты ---
err(){ printf "[ERR] %s\n" "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Путь к инжектору
detect_inj(){
  local top inj
  top="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/wheelzone-script-utils")"
  inj="$top/scripts/utils/wz_uuid_yaml_injector.sh"
  [[ -x "$inj" ]] || inj="$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_yaml_injector.sh"
  [[ -x "$inj" ]] && { printf "%s" "$inj"; return 0; }
  return 1
}

# Получение значения ключа (из plain или commented YAML)
yget(){
  local key="$1" f="$2"
  # plain
  awk -v k="$key" '
    BEGIN{inY=0}
    NR==1 && /^---[[:space:]]*$/ {inY=1; next}
    inY==1 && /^---[[:space:]]*$/ {exit}
    inY==1 {
      if ($0 ~ "^[[:space:]]*" k ":[[:space:]]*") {
        sub("^[[:space:]]*" k ":[[:space:]]*","",$0); print; exit
      }
    }' "$f" 2>/dev/null || true
  # commented
  awk -v k="$key" '
    BEGIN{inY=0}
    NR<=200{
      if (inY==0 && $0 ~ /^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=1; next}
      if (inY==1 && $0 ~ /^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){exit}
      if (inY==1){
        line=$0; sub(/^[[:space:]]*#[[:space:]]*/,"",line)
        if (line ~ "^[[:space:]]*" k ":[[:space:]]*"){ sub("^[[:space:]]*" k ":[[:space:]]*","",line); print line; exit }
      }
    }' "$f" 2>/dev/null || true
}

is_uuid_v4(){ [[ "$1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]; }
is_md5(){ [[ "$1" =~ ^[0-9a-f]{32}$ ]]; }
is_slug(){ [[ "$1" =~ ^[a-z0-9-]+$ ]]; }
is_type(){ [[ "$1" =~ ^(${TYPE_WHITELIST})$ ]]; }
is_iso8601z(){ [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; }

json_log(){ # level, op, file, msg, extra(json or empty)
  local level="$1" op="$2" file="$3" msg="$4" extra="${5:-}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ -n "$extra" ]]; then
    printf '{"level":"%s","ts":"%s","service":"wz-check","op":"%s","file":"%s","msg":"%s","extra":%s}\n' "$level" "$ts" "$op" "$file" "$msg" "$extra"
  else
    printf '{"level":"%s","ts":"%s","service":"wz-check","op":"%s","file":"%s","msg":"%s"}\n' "$level" "$ts" "$op" "$file" "$msg"
  fi
}

# --- проверка одного файла ---
check_one(){
  local f="$1" strict="${2:-yes}"
  [[ -f "$f" ]] || { json_log "ERROR" "check" "$f" "file not found"; return 4; }

  local miss=() invalid=()
  # читаем значения
  local uuid fu slug type created_at md5
  uuid="$(yget uuid "$f" | tr -d '\r' | xargs || true)"
  fu="$(yget fractal_uuid "$f" | tr -d '\r' | xargs || true)"
  slug="$(yget slug "$f" | tr -d '\r' | xargs || true)"
  type="$(yget type "$f" | tr -d '\r' | xargs || true)"
  created_at="$(yget created_at "$f" | tr -d '\r' | xargs || true)"
  md5="$(yget content_md5 "$f" | tr -d '\r' | xargs || true)"

  # обязательные
  [[ -n "$uuid" ]] || miss+=("uuid")
  [[ -n "$fu"   ]] || miss+=("fractal_uuid")
  [[ -n "$slug" ]] || miss+=("slug")
  [[ -n "$type" ]] || miss+=("type")
  [[ -n "$created_at" ]] || miss+=("created_at")
  [[ -n "$md5" ]] || miss+=("content_md5")

  if (( ${#miss[@]} > 0 )); then
    json_log "ERROR" "check" "$f" "missing required keys" "$(printf '{"missing":%s}' "$(printf '%s\n' "${miss[@]}" | awk 'BEGIN{printf "["} {if(NR>1)printf ","; printf "\"%s\"", $0} END{printf "]"}')")"
    return 2
  fi

  # форматы
  is_uuid_v4 "$uuid" || invalid+=("uuid:format")
  is_uuid_v4 "$fu"   || invalid+=("fractal_uuid:format")
  is_slug "$slug"    || invalid+=("slug:format")
  is_type "$type"    || invalid+=("type:value")
  is_iso8601z "$created_at" || invalid+=("created_at:format")
  is_md5 "$md5"      || invalid+=("content_md5:format")

  if (( ${#invalid[@]} > 0 )); then
    json_log "ERROR" "check" "$f" "invalid values" "$(printf '{"invalid":%s}' "$(printf '%s\n' "${invalid[@]}" | awk 'BEGIN{printf "["} {if(NR>1)printf ","; printf "\"%s\"", $0} END{printf "]"}')")"
    return 3
  fi

  json_log "INFO" "check" "$f" "ok"
  return 0
}

usage(){
cat <<USG
check_rule.sh v2.0
Usage:
  $0 --file <path> [--file <path> ...] [--auto] [--json]
  # --auto: попытается исправить недостающие ключи через wz-preproc --mode augment, затем перепроверит
USG
}

main(){
  local files=() auto="no" json_only="no"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file) files+=("$2"); shift 2;;
      --auto) auto="yes"; shift;;
      --json) json_only="yes"; shift;;
      --help|-h) usage; exit 0;;
      *) files+=("$1"); shift;;
    esac
  done
  [[ ${#files[@]} -gt 0 ]] || { usage; exit 1; }

  local inj rc=0
  if [[ "$auto" == "yes" ]]; then
    if inj="$(detect_inj)"; then
      # тихая аугментация с требованиями
      "$inj" --mode augment --require "$REQ_KEYS" "${files[@]}" >/dev/null 2>&1 || true
    else
      json_log "WARN" "auto" "-" "injector not found; skip auto-fix"
    fi
  fi

  local f r any_err=0
  for f in "${files[@]}"; do
    r=0
    check_one "$f" || r=$?
    # суммарный код: 0 ok, 2 missing, 3 invalid, 4 error -> берём максимальный (хуже)
    (( r > any_err )) && any_err=$r
  done
  exit $any_err
}
main "$@"
