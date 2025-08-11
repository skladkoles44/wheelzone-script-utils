#!/data/data/com.termux/files/usr/bin/bash
# WZ History Fix Headers v3.1-safe — без export -f/xargs, BOM/CRLF-safe, MD5 по телу
set -Eeuo pipefail

SRC="${SRC_DIR:-$HOME/.wz_history}"
LOG_DIR="${LOG_DIR:-$HOME/.wz_logs}"
LOG="$LOG_DIR/wz_fix_headers.log"

mkdir -p "$LOG_DIR" "$SRC"

log(){ echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# MD5 только по телу (после второго ---), CRLF убираем
md5_body(){
  local f="$1" tmp="$(mktemp)"
  awk 'BEGIN{h=0} /^---$/{h++;next} h>=2{print}' "$f" | sed 's/\r$//' > "$tmp"
  md5sum "$tmp" | awk '{print $1}'
  rm -f "$tmp"
}

uuid_gen(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "local-$(date +%s)"; }

process_one(){
  local f="$1"
  [ -L "$f" ] && { log "skip symlink: $f"; return; }
  [ -s "$f" ] || { log "skip empty: $f"; return; }

  # Нормализуем BOM/CRLF в tmp
  local tmp_norm="$(mktemp)"
  sed '1s/^\xEF\xBB\xBF//;s/\r$//' "$f" > "$tmp_norm"

  # Извлекаем шапку, если есть
  local header_end=-1 uuid="" fuuid="" created="" format=""
  mapfile -t L < "$tmp_norm" || true
  if [ "${#L[@]}" -ge 3 ] && [ "${L[0]}" = "---" ]; then
    for i in "${!L[@]}"; do
      [ "$i" -gt 0 ] && [ "${L[$i]}" = "---" ] && { header_end="$i"; break; }
    done
    if [ "$header_end" -gt 0 ]; then
      for ((i=1; i<header_end; i++)); do
        case "${L[$i]}" in
          uuid:*) uuid="${L[$i]#uuid: }" ;;
          fractal_uuid:*) fuuid="${L[$i]#fractal_uuid: }" ;;
          created_utc:*) created="${L[$i]#created_utc: }" ;;
          format:*) format="${L[$i]#format: }" ;;
        esac
      done
    fi
  fi

  # Значения по умолчанию
  if [ -z "$uuid" ]; then
    uuid="$(basename "$f" | awk -F'[_-]' '{print $5}')"
    [ -n "${uuid:-}" ] || uuid="$(uuid_gen)"
  fi
  [ -n "${fuuid:-}" ] || fuuid="PENDING"
  [ -n "${created:-}" ] || created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "${format:-}" ] || format="wz-chat-md/v1"

  local body_hash; body_hash="$(md5_body "$tmp_norm")"

  # Пересобираем файл: новая шапка + тело (после 2-го ---)
  local tmp_out="$(mktemp)"
  {
    echo "---"
    echo "uuid: $uuid"
    echo "fractal_uuid: $fuuid"
    echo "created_utc: $created"
    echo "format: $format"
    echo "content_hash_md5: $body_hash"
    echo "---"
    awk 'BEGIN{h=0} /^---$/{h++;next} h>=2{print}' "$tmp_norm"
  } > "$tmp_out"

  install -m 600 "$tmp_out" "${f}.tmp.swap"
  mv -f "${f}.tmp.swap" "$f"
  rm -f "$tmp_norm" "$tmp_out"
  log "fixed: $(basename "$f") md5=$body_hash"
}

main(){
  # Обрабатываем только .md в SRC (без рекурсии)
  shopt -s nullglob
  for f in "$SRC"/*.md; do
    process_one "$f"
  done
  echo "[fix_headers] done @ $(date -u +%H:%M:%SZ)"
}

main "$@"
