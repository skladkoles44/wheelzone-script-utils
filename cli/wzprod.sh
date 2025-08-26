#!/usr/bin/env bash
# WheelZone :: wzprod — канонический просмотрщик Production Prompt
# Версия: 1.1.0 | Termux/Android 15 | без root
set -Eeuo pipefail; IFS=$'\n\t'

PROMPT_PATH="${PROMPT_PATH:-$HOME/wz-wiki/docs/ai_prompts/wheelzone_production_prompt_v3.1.md}"
PROMPT_DIR="${PROMPT_DIR:-$HOME/wz-wiki/docs/ai_prompts}"

usage() {
  cat <<USAGE
wzprod — быстрый доступ к WheelZone Production Prompt

Использование:
  wzprod                   # вывести PROMPT_PATH в stdout
  wzprod --pager           # открыть в less -R
  wzprod --pretty          # отрендерить красиво (glow|bat|less -R)
  wzprod --menu            # выбрать .md из PROMPT_DIR через fzf и вывести
  wzprod --path            # показать текущий путь PROMPT_PATH
  wzprod --list            # перечислить доступные .md в PROMPT_DIR
  wzprod --copy            # скопировать PROMPT_PATH в буфер (Termux)
  wzprod --export FILE     # сохранить копию атомарно в FILE
  wzprod --version         # версия утилиты
  wzprod --help            # справка

ENV:
  PROMPT_PATH  — путь к .md (по умолчанию: $HOME/wz-wiki/docs/ai_prompts/wheelzone_production_prompt_v3.1.md)
  PROMPT_DIR   — каталог с промптами (по умолчанию: $HOME/wz-wiki/docs/ai_prompts)
USAGE
}

ensure_exists() {
  if [ ! -f "$PROMPT_PATH" ]; then
    printf '\033[1;31mФайл промпта не найден:\033[0m %s\n' "$PROMPT_PATH" >&2
    exit 2
  fi
}

pretty_show() {
  ensure_exists
  if command -v glow >/dev/null 2>&1; then
    glow -p "$PROMPT_PATH"
  elif command -v bat >/dev/null 2>&1; then
    bat --paging=always --style=plain --language=markdown "$PROMPT_PATH"
  else
    less -R "$PROMPT_PATH"
  fi
}

menu_pick() {
  if ! command -v fzf >/dev/null 2>&1; then
    printf '\033[1;33mНет fzf — показываю список.\033[0m\n'
    list_files
    exit 2
  fi
  [ -d "$PROMPT_DIR" ] || { echo "Каталог не найден: $PROMPT_DIR" >&2; exit 2; }
  sel="$(find "$PROMPT_DIR" -maxdepth 1 -type f -name '*.md' | sort | fzf --prompt='prompts> ' --height=80% --border --ansi || true)"
  [ -n "$sel" ] || exit 0
  PROMPT_PATH="$sel"
  pretty_show
}

list_files() {
  [ -d "$PROMPT_DIR" ] || { echo "Каталог не найден: $PROMPT_DIR" >&2; exit 2; }
  find "$PROMPT_DIR" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort
}

copy_clip() {
  ensure_exists
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    nohup termux-clipboard-set < "$PROMPT_PATH" >/dev/null 2>&1 &
    printf '\033[1;92mСкопировано в буфер Termux.\033[0m\n'
  else
    printf '\033[1;33mtermux-clipboard-set недоступен.\033[0m\n'
  fi
}

export_atomic() {
  ensure_exists
  dst="${1:-}"
  [ -n "$dst" ] || { echo "Укажи файл: wzprod --export /path/file.md" >&2; exit 2; }
  umask 077
  tmp="$(mktemp "${dst}.XXXX")"
  cp -- "$PROMPT_PATH" "$tmp"
  mv -- "$tmp" "$dst"
  printf '\033[1;92mСохранено:\033[0m %s\n' "$dst"
}

case "${1:-}" in
  --help|-h) usage ;;
  --version|-V) echo "wzprod 1.1.0" ;;
  --path) echo "$PROMPT_PATH" ;;
  --list) list_files ;;
  --pager) ensure_exists; less -R "$PROMPT_PATH" ;;
  --pretty) pretty_show ;;
  --menu) menu_pick ;;
  --copy) copy_clip ;;
  --export) shift; export_atomic "${1:-}" ;;
  "" ) ensure_exists; cat "$PROMPT_PATH" ;;
  * ) printf 'Неизвестная опция: %s\n\n' "${1:-}" >&2; usage; exit 2 ;;
esac
