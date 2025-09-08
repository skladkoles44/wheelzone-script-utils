#!/usr/bin/env bash
# WheelZone :: ClipRun — гарантированный лог + буфер обмена
# fractal_uuid=2c4af8f9-2e9a-4d0e-bf77-7f7a6be6c9b4
set -uo pipefail
IFS=$'\n\t'

LOG_DIR="/storage/emulated/0/Download/project_44/Logs"
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
# имя можно переопределить через WZ_NAME
NAME="${WZ_NAME:-wz_run}"
RUN_LOG="$LOG_DIR/${NAME}_${TS}.txt"

# 🎨 рандомный цвет заголовка
COLORS=(31 32 33 34 35 36); CLR=${COLORS[$RANDOM % ${#COLORS[@]}]}

# Собираем команду из аргументов/STDIN
# Варианты:
#   wz_cliprun.sh -- cmd args...
#   some_pipeline | wz_cliprun.sh (в этом случае читаем STDIN как тело)
print_header() {
  printf "\033[%sm==[ %s :: %s ]==\033[0m\n" "$CLR" "$NAME" "$TS"
}

copy_clip() {
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    termux-clipboard-set < "$RUN_LOG" || true
    echo "[CLIPBOARD] copied" >> "$RUN_LOG"
  else
    echo "[CLIPBOARD] termux-clipboard-set not found" >> "$RUN_LOG"
  fi
}

# Если stdin не пустой — просто зеркалим его в лог, иначе выполняем команду из аргументов
if [ ! -t 0 ] && read -r -t 0.01 _peek; then
  # есть STDIN: печатаем шапку, кладём уже прочитанное и всё остальное
  { print_header; printf "%s\n" "$_peek"; cat; } | tee "$RUN_LOG" >/dev/null
  copy_clip
  exit 0
else
  if [ "$#" -eq 0 ] || [ "$1" = "--help" ]; then
    echo "Usage:"
    echo "  $0 -- <command with args>     # run command, log + clipboard"
    echo "  <producer> | $0               # pipe mode: stdin -> log + clipboard"
    echo "Env: WZ_NAME=custom_name        # prefix for log filename/header"
    exit 2
  fi
  shift || true
  TMP="$(mktemp)"
  {
    print_header
    # shellcheck disable=SC2068
    "$@" 2>&1
  } | tee "$TMP"
  RC=${PIPESTATUS[0]}
  mv "$TMP" "$RUN_LOG"
  copy_clip
  exit $RC
fi
