#!/usr/bin/env bash
# WheelZone :: wz_uuid_yaml_injector.sh
# v1.8.0-prod — добавлен content_md5 (MD5 контента без YAML-хедера; shebang остаётся в хэше).
# Совм-сть CLI и поведения сохранена.

set -Eeuo pipefail
IFS=$'\n\t'

: "${WZ_UUID_API:=}"
: "${WZ_SLUG_MAX:=64}"
: "${WZ_DESC_MAX:=160}"
: "${WZ_NOW_FMT:="+%Y-%m-%dT%H:%M:%SZ"}"
: "${WZ_CHECK_RULE:=}"
: "${WZ_SUPPORTED_EXT:=sh,py,md,txt,yaml,yml}"

err(){ printf "[ERR] %s\n" "$*" >&2; }
inf(){ printf "[INFO] %s\n" "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# ---------- UUID ----------
uuid_from_api(){
  [[ -n "$WZ_UUID_API" ]] || return 1
  have curl || return 1
  local r; r="$(curl -fsSL --connect-timeout 2 --max-time 3 "$WZ_UUID_API" 2>/dev/null || true)"
  [[ -n "$r" ]] || return 1
  if [[ "$r" =~ uuid\"[[:space:]]*:[[:space:]]*\"([a-f0-9-]{36})\" ]]; then printf "%s" "${BASH_REMATCH[1]}"; return 0; fi
  if [[ "$r" =~ ^[a-f0-9-]{36}$ ]]; then printf "%s" "$r"; return 0; fi
  return 1
}
uuid_local(){
  if [[ -r /proc/sys/kernel/random/uuid ]]; then head -c 36 /proc/sys/kernel/random/uuid 2>/dev/null || true; return 0; fi
  if have python3; then python3 - <<'PY' || true
import uuid; print(str(uuid.uuid4()))
PY
    return 0; fi
  if have awk; then
    awk 'BEGIN{srand();h="0123456789abcdef";for(i=0;i<36;i++){if(i==8||i==13||i==18||i==23){printf"-";continue}if(i==14){printf"4";continue}c=int(rand()*16);if(i==19){c=(and(c,3)+8)}printf"%s",substr(h,c+1,1)}print""}'
    return 0
  fi
  return 1
}
gen_uuid(){ local u; u="$(uuid_from_api || true)"; [[ -n "$u" ]] || u="$(uuid_local || true)"; [[ -n "$u" ]] || { err "uuid: не удалось получить"; return 1; }; printf "%s" "$u"; }

# ---------- SLUG/TYPE/DESC ----------
slugify(){ local s="${1,,}"; s="$(printf "%s" "$s" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"; printf "%s" "${s:0:$WZ_SLUG_MAX}"; }
deduce_type(){ case "$1" in *.sh) echo script-bash;; *.py) echo script-python;; *.md) echo document-md;; *.yaml|*.yml) echo document-yaml;; *.txt) echo document-text;; *) echo artifact;; esac; }
read_title_guess(){ local h; h="$(grep -m1 -E '^[[:space:]]*# ' "$1" 2>/dev/null || true)"; [[ -n "$h" ]] && printf "%s" "${h#\# }" || basename "$1"; }
make_description(){ local t d; t="$(read_title_guess "$1")"; d="Auto: $(basename "$1") — ${t}"; d="$(printf "%s" "$d" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g')"; printf "%s" "${d:0:$WZ_DESC_MAX}"; }

# ---------- HEADER DETECT/PARSE ----------
is_shebang(){ head -n1 "$1" 2>/dev/null | grep -q '^#!'; }
has_plain_yaml_header(){ awk 'NR==1&&/^---[[:space:]]*$/ {inY=1;next} inY&&/^---[[:space:]]*$/ {print "YES";exit} NR>200{exit}' "$1" 2>/dev/null | grep -q YES; }
has_commented_yaml_header(){ awk 'BEGIN{inY=0} NR<=200{ if(!inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=1;next} if(inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){print"YES";exit} }' "$1" 2>/dev/null | grep -q YES; }

print_header(){
  local f="$1"
  if has_plain_yaml_header "$f"; then
    awk 'NR==1&&/^---[[:space:]]*$/{inY=1;next} inY&&/^---[[:space:]]*$/{exit} inY{print}' "$f"; return 0
  fi
  if has_commented_yaml_header "$f"; then
    awk 'BEGIN{inY=0} NR<=200{ if(!inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=1;next} if(inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){exit} if(inY){gsub(/^[[:space:]]*#[[:space:]]*/,""); print} }' "$f"; return 0
  fi
  err "print: YAML-хедер не найден -> $f"; return 3
}
yget(){ local k="$1" f="$2"
  awk -v k="$k" 'BEGIN{inY=0} NR==1&&/^---[[:space:]]*$/ {inY=1;next} inY&&/^---[[:space:]]*$/ {exit} inY&&$0 ~ "^[[:space:]]*" k ":[[:space:]]*" {sub("^[[:space:]]*" k ":[[:space:]]*","",$0); print; exit}' "$f" 2>/dev/null || true
  awk -v k="$k" 'BEGIN{inY=0} NR<=200{ if(!inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=1;next} if(inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){exit} if(inY){line=$0; sub(/^[[:space:]]*#[[:space:]]*/,"",line); if(line ~ "^[[:space:]]*" k ":[[:space:]]*"){ sub("^[[:space:]]*" k ":[[:space:]]*","",line); print line; exit } } }' "$f" 2>/dev/null || true
}

# ---------- CONTENT WITHOUT HEADER (для MD5) ----------
content_without_header(){
  # печатает в stdout файл без YAML-хедера. Shebang сохраняется.
  local f="$1"
  if has_plain_yaml_header "$f"; then
    awk 'BEGIN{inY=0}
         NR==1 && /^---[[:space:]]*$/ {inY=1; next}
         inY==1 && /^---[[:space:]]*$/ {inY=0; next}
         inY==0 {print}' "$f"
    return 0
  fi
  if has_commented_yaml_header "$f"; then
    awk 'BEGIN{inY=0; removed=0}
         NR==1 && /^#!/ {print; next}
         NR<=200 {
           if (!removed && !inY && $0 ~ /^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=1; next}
           if (inY && $0 ~ /^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=0; removed=1; next}
         }
         inY==0 {print}' "$f"
    return 0
  fi
  # если шапки нет — вернуть как есть
  cat "$f"
}

md5_hex(){
  if have md5sum; then md5sum | awk '{print $1}'; return 0; fi
  if have openssl; then openssl dgst -md5 -r | awk '{print $1}'; return 0; fi
  if have python3; then
    python3 - <<'PY'
import sys,hashlib
print(hashlib.md5(sys.stdin.buffer.read()).hexdigest())
PY
    return 0
  fi
  err "нет md5sum/openssl/python3 для расчёта MD5"; return 1
}

calc_content_md5(){
  local f="$1"
  content_without_header "$f" | md5_hex
}

# ---------- RENDER ----------
render_plain_yaml(){ cat <<PLN
---
uuid: $1
fractal_uuid: $2
slug: $3
created_at: $4
type: $5
description: "$6"
content_md5: $7
x-uuid-source: $8
---
PLN
}
render_commented_yaml(){ cat <<CMT
# ---
# uuid: $1
# fractal_uuid: $2
# slug: $3
# created_at: $4
# type: $5
# description: "$6"
# content_md5: $7
# x-uuid-source: $8
# ---
CMT
}

# ---------- CORE OPS ----------
inject_header(){
  local f="$1" src="api_or_local" u s now t desc md5
  u="$(gen_uuid)" || return 10
  [[ -z "$WZ_UUID_API" ]] && src="local"
  s="$(slugify "$(basename "$f")")"
  t="$(deduce_type "$f")"
  desc="$(make_description "$f")"
  now="$(date -u "$WZ_NOW_FMT")"
  md5="$(calc_content_md5 "$f")" || md5=""

  local tmp; tmp="$(mktemp 2>/dev/null || printf "%s" "${TMPDIR:-/tmp}/wz_yaml_$$")"
  if is_shebang "$f"; then
    { head -n1 "$f"; render_commented_yaml "$u" "$u" "$s" "$now" "$t" "$desc" "$md5" "$src"; tail -n +2 "$f"; } > "$tmp"
  else
    { render_plain_yaml "$u" "$u" "$s" "$now" "$t" "$desc" "$md5" "$src"; cat "$f"; } > "$tmp"
  fi
  cat "$tmp" > "$f"; rm -f "$tmp"
  inf "Injected header [$t] -> $f (uuid=$u, md5=$md5)"
}

augment_header(){
  local f="$1" commented="no"
  if has_plain_yaml_header "$f"; then commented="no"
  elif has_commented_yaml_header "$f"; then commented="yes"
  else err "augment: YAML-хедер не найден -> $f"; return 20; fi

  local u fu s now t desc src md5 oldmd5
  u="$(yget uuid "$f")"
  fu="$(yget fractal_uuid "$f")"
  s="$(yget slug "$f")"
  t="$(yget type "$f")"
  desc="$(yget description "$f")"
  src="$(yget x-uuid-source "$f")"
  oldmd5="$(yget content_md5 "$f")"
  md5="$(calc_content_md5 "$f")" || md5="$oldmd5"

  [[ -n "$u" ]]  || u="$(gen_uuid)" || return 21
  [[ -n "$fu" ]] || fu="$u"
  [[ -n "$s" ]]  || s="$(slugify "$(basename "$f")")"
  [[ -n "$t" ]]  || t="$(deduce_type "$f")"
  [[ -n "$desc" ]] || desc="$(make_description "$f")"
  now="$(date -u "$WZ_NOW_FMT")"
  [[ -n "$src" ]] || src="$([[ -n "$WZ_UUID_API" ]] && echo api_or_local || echo local)"

  local tmp; tmp="$(mktemp 2>/dev/null || printf "%s" "${TMPDIR:-/tmp}/wz_yaml_$$")"
  if [[ "$commented" == "no" ]]; then
    awk -v hdr="$(render_plain_yaml "$u" "$fu" "$s" "$now" "$t" "$desc" "$md5" "$src")" '
      BEGIN{inY=0}
      NR==1&&/^---[[:space:]]*$/ {print hdr; inY=1; next}
      inY==1&&/^---[[:space:]]*$/ {inY=0; next}
      inY==0 {print}
    ' "$f" > "$tmp"
  else
    awk -v hdr="$(render_commented_yaml "$u" "$fu" "$s" "$now" "$t" "$desc" "$md5" "$src")" '
      BEGIN{inY=0;done=0}
      NR==1&&/^#!/ {print; next}
      NR<=200{
        if(!done && !inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){print hdr; inY=1; next}
        if(inY && $0~/^[[:space:]]*#[[:space:]]*---[[:space:]]*$/){inY=0; done=1; next}
      }
      inY==0 {print}
    ' "$f" > "$tmp"
  fi
  cat "$tmp" > "$f"; rm -f "$tmp"
  inf "Augmented header -> $f (uuid=$u, md5=$md5)"
}

require_keys(){ local f="$1" csv="$2" miss=0 k; IFS=, read -r -a KEYS <<<"$csv"; for k in "${KEYS[@]}"; do [[ -z "$k" ]]&&continue; [[ -n "$(yget "$k" "$f")" ]] || { printf "[AUDIT][MISS] %s: %s\n" "$f" "$k"; miss=1; }; done; return $miss; }

process_file(){
  local f="$1" mode="$2" req="$3" audit="${4:-no}"
  [[ -f "$f" ]] || { err "нет файла: $f"; return 2; }
  if file --brief --mime "$f" 2>/dev/null | grep -qi 'charset=binary'; then inf "skip binary: $f"; return 0; fi
  local ext="${f##*.}" ok="no"; IFS=, read -r -a exts <<<"${WZ_SUPPORTED_EXT}"; for e in "${exts[@]}"; do [[ "$ext" == "$e" ]] && { ok="yes"; break; }; done
  [[ "$ok" == "yes" ]] || { inf "skip ext: $f"; return 0; }

  case "$mode" in
    inject) if has_plain_yaml_header "$f" || has_commented_yaml_header "$f"; then inf "skip: header exists -> $f"; else inject_header "$f"; fi ;;
    augment) if has_plain_yaml_header "$f" || has_commented_yaml_header "$f"; then augment_header "$f"; else inf "no header to augment -> $f"; fi ;;
    *) err "unknown mode: $mode"; return 9;;
  esac

  [[ -n "$req" ]] && require_keys "$f" "$req" || true
  [[ "$audit" == "yes" ]] && { print_header "$f" || true; }

  local chk="${WZ_CHECK_RULE:-}"; if [[ -z "$chk" ]]; then local top; top="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"; [[ -x "$top/scripts/utils/check_rule.sh" ]] && chk="$top/scripts/utils/check_rule.sh" || chk=""; fi
  [[ -n "$chk" && -x "$chk" ]] && "$chk" --auto --file "$f" || true
}

usage(){ cat <<USG
wz_uuid_yaml_injector.sh v1.8.0-prod
Usage:
  $0 FILE...                              # inject (default)
  $0 --mode inject|augment --require k1,k2 --audit FILE...
  $0 --staged-only [--dry-run] [--mode ...] [--require ...] [--audit]
  $0 --print FILE
USG
}

main(){
  local mode="inject" dry="no" staged="no" req="" audit="no" print_only="no" args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode) mode="${2:-inject}"; shift 2;;
      --dry-run) dry="yes"; shift;;
      --staged-only) staged="yes"; shift;;
      --require) req="${2:-}"; shift 2;;
      --audit) audit="yes"; shift;;
      --print) print_only="yes"; shift;;
      --help|-h) usage; exit 0;;
      --) shift; break;;
      *) args+=("$1"); shift;;
    esac
  done
  if [[ "$print_only" == "yes" ]]; then [[ ${#args[@]} -eq 1 ]] || { usage; exit 1; }; print_header "${args[0]}"; exit $?; fi
  if [[ "$staged" == "yes" ]]; then
    local files rc=0 f; files="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)"; [[ -n "$files" ]] || { inf "нет застейдженных файлов"; exit 0; }
    while IFS= read -r f; do
      case "$f" in
        *.sh|*.py|*.md|*.txt|*.yaml|*.yml)
          if [[ "$dry" == "yes" ]]; then inf "[DRY] $mode -> $f"; require_keys "$f" "$req" || rc=$?; [[ "$audit"=="yes" ]] && print_header "$f" || true
          else process_file "$f" "$mode" "$req" "$audit" || rc=$?; git add -- "$f" 2>/dev/null || true; fi ;;
        *) inf "skip ext: $f" ;;
      esac
    done <<< "$files"; exit $rc
  fi
  [[ ${#args[@]} -gt 0 ]] || { usage; exit 1; }
  local rc=0 f; for f in "${args[@]}"; do
    if [[ "$dry" == "yes" ]]; then inf "[DRY] $mode -> $f"; require_keys "$f" "$req" || rc=$?; [[ "$audit"=="yes" ]] && print_header "$f" || true
    else process_file "$f" "$mode" "$req" "$audit" || rc=$?; fi
  done; exit $rc
}
main "$@"
