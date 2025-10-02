#!/bin/bash
set -Eeuo pipefail

REMOTE="${REMOTE:-gdrive}"
ROOT_PATH="${ROOT_PATH:-/}"
OUT_DIR="${OUT_DIR:-./reports}"
mkdir -p "$OUT_DIR"

usage() {
  cat <<USAGE
Использование:
  bash $0 build              — собрать отчет в .xz (TSV внутри)
  bash $0 show <file.xz>     — показать распакованный отчет (через less)
  bash $0 grep <file.xz> PAT — отфильтровать по regex и показать
  bash $0 head <file.xz> N   — показать первые N строк
  bash $0 copy <file.xz> SEL — скопировать (Termux) вывод селектора SEL:
                                'head:N' | 'grep:REGEX' | 'all'
  bash $0 latest CMD [...]   — работать с последним отчётом (build → show/head/grep/copy)

Формат строк TSV: size_bytes<TAB>modtime<TAB>path
Переменные окружения: REMOTE, ROOT_PATH, OUT_DIR
USAGE
}

build_report() {
  TS="$(date -u +%Y%m%dT%H%M%SZ)"
  OUT="$OUT_DIR/archives_${TS}.tsv.xz"
  rclone lsjson "$REMOTE:$ROOT_PATH" -R --files-only --hash --hash-type md5 --fast-list \
    | jq -r '.[] | select(.Name|test("\\.(zip|tar|gz|xz|7z|rar|bundle|tgz|tbz2)$";"i")) 
      | "\(.Size)\t\(.ModTime)\t\(.Path)"' \
    | xz -9e >"$OUT"
  echo "[OK] Report saved: $OUT"
}

show_report() {
  xz -dc "$1" | less
}

grep_report() {
  xz -dc "$1" | grep -E "$2" | less || true
}

head_report() {
  xz -dc "$1" | head -n "$2" || true
}

copy_report() {
  sel="$2"
  if [[ "$sel" == head:* ]]; then
    xz -dc "$1" | head -n "${sel#head:}" | termux-clipboard-set || true
  elif [[ "$sel" == grep:* ]]; then
    xz -dc "$1" | grep -E "${sel#grep:}" | termux-clipboard-set || true
  elif [[ "$sel" == all ]]; then
    xz -dc "$1" | termux-clipboard-set || true
  else
    echo "[ERR] Unknown selector: $sel" >&2
    exit 1
  fi
  echo "[OK] Copied to clipboard"
}

latest_report() {
  LAST="$(ls -1t "$OUT_DIR"/archives_*.xz 2>/dev/null | head -1 || true)"
  if [ -z "$LAST" ]; then
    echo "[ERR] Нет отчётов в $OUT_DIR" >&2
    exit 1
  fi
  case "${1:-}" in
    show) show_report "$LAST" ;;
    grep) shift; grep_report "$LAST" "$@" ;;          # pattern может содержать пробелы
    head) shift; head_report "$LAST" "${1:-10}" ;;
    copy) shift; copy_report "$LAST" "${1:-all}" ;;
    *) echo "[ERR] Unknown subcommand for latest: ${1:-<none>}" >&2; usage; exit 1 ;;
  esac
}

case "${1:-}" in
  build) build_report ;;
  show) show_report "${2:?file.xz required}" ;;
  grep) grep_report "${2:?file.xz required}" "${3:?pattern required}" ;;
  head) head_report "${2:?file.xz required}" "${3:?N required}" ;;
  copy) copy_report "${2:?file.xz required}" "${3:?selector required}" ;;
  latest) shift; latest_report "$@" ;;
  *) usage; exit 1 ;;
esac
