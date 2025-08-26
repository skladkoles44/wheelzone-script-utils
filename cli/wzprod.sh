#!/usr/bin/env bash
# WheelZone :: wzprod — просмотрщик/помощник для Production Prompt
# Версия: 1.2.0 | Termux/Android 15 | без root
set -Eeuo pipefail; IFS=$'\n\t'

PROMPT_PATH="${PROMPT_PATH:-$HOME/wz-wiki/docs/ai_prompts/wheelzone_production_prompt_v3.1.md}"
PROMPT_DIR="${PROMPT_DIR:-$HOME/wz-wiki/docs/ai_prompts}"

usage() {
  cat <<USAGE
wzprod — быстрый доступ к WheelZone Production Prompt

Использование:
  wzprod                     # вывести PROMPT_PATH в stdout
  wzprod --pager             # открыть в less -R
  wzprod --pretty            # красивый рендер (glow|bat|less -R)
  wzprod --menu              # выбрать .md из каталога PROMPT_DIR (fzf)
  wzprod --path              # показать путь PROMPT_PATH
  wzprod --list              # перечислить .md в PROMPT_DIR
  wzprod --copy              # скопировать PROMPT_PATH в буфер (Termux)
  wzprod --export FILE       # сохранить копию атомарно в FILE
  wzprod --apply [FILE]      # подготовить сообщение для чата: код + строка "opt"
  wzprod --apply-exp [FILE]  # то же, но с триггером "opt ⚠️"
  wzprod --install-deps      # установить glow/bat/fzf при наличии pkg
  wzprod --version           # версия утилиты
  wzprod --help              # справка

ENV:
  PROMPT_PATH — путь к основному .md
  PROMPT_DIR  — каталог с промптами
USAGE
}

ensure_exists() { [ -f "$PROMPT_PATH" ] || { printf '\033[1;31mNo prompt:\033[0m %s\n' "$PROMPT_PATH" >&2; exit 2; }; }

pretty_show() {
  ensure_exists
  if command -v glow >/dev/null 2>&1; then glow -p "$PROMPT_PATH"
  elif command -v bat >/dev/null 2>&1; then bat --paging=always --style=plain --language=markdown "$PROMPT_PATH"
  else less -R "$PROMPT_PATH"; fi
}

list_files() { [ -d "$PROMPT_DIR" ] || { echo "No dir: $PROMPT_DIR" >&2; exit 2; }; find "$PROMPT_DIR" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort; }

menu_pick() {
  command -v fzf >/dev/null 2>&1 || { printf '\033[1;33mНет fzf — показываю список.\033[0m\n'; list_files; exit 2; }
  [ -d "$PROMPT_DIR" ] || { echo "No dir: $PROMPT_DIR" >&2; exit 2; }
  sel="$(find "$PROMPT_DIR" -maxdepth 1 -type f -name '*.md' | sort | fzf --prompt='prompts> ' --height=80% --border --ansi || true)"
  [ -n "$sel" ] || exit 0
  PROMPT_PATH="$sel"; pretty_show
}

copy_clip() {
  ensure_exists
  if command -v termux-clipboard-set >/dev/null 2>&1; then nohup termux-clipboard-set < "$PROMPT_PATH" >/dev/null 2>&1 & printf '\033[1;92mКопия в буфере Termux.\033[0m\n'
  else printf '\033[1;33mtermux-clipboard-set недоступен.\033[0m\n'; fi
}

export_atomic() {
  ensure_exists; dst="${1:-}"; [ -n "$dst" ] || { echo "Укажи файл: wzprod --export /path/file.md" >&2; exit 2; }
  umask 077; tmp="$(mktemp "${dst}.XXXX")"; cp -- "$PROMPT_PATH" "$tmp"; mv -- "$tmp" "$dst"; printf '\033[1;92mСохранено:\033[0m %s\n' "$dst"
}

detect_lang() {
  p="${1:-}"; case "$p" in
    *.sh|*.bash) echo "bash" ;;
    *.py) echo "python" ;;
    *.sql) echo "sql" ;;
    *.yaml|*.yml) echo "yaml" ;;
    *.json) echo "json" ;;
    *) echo "" ;;
  esac
}

apply_helper() {
  # Читает код из файла или stdin, заворачивает в Markdown + добавляет "opt"/"opt ⚠️"
  trigger="$1"; src="${2:-}"
  tmp_code="$(mktemp)"
  if [ -n "$src" ]; then cat -- "$src" > "$tmp_code"; else cat - > "$tmp_code"; fi
  lang="$(detect_lang "$src")"
  printf '\n\033[1;36mГотовлю сообщение для чата…\033[0m\n'
  tmp_msg="$(mktemp).md"
  {
    printf '```%s\n' "$lang"
    cat "$tmp_code"
    printf '\n```\n\n%s\n' "$trigger"
  } > "$tmp_msg"

  # Копируем в буфер — сразу можно вставлять в чат
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    nohup termux-clipboard-set < "$tmp_msg" >/dev/null 2>&1 &
    printf '\033[1;92mСообщение скопировано в буфер. Вставляй в чат.\033[0m\n'
  else
    printf '\033[1;33mtermux-clipboard-set нет — показываю ниже. Скопируй вручную.\033[0m\n'
    cat "$tmp_msg"
  fi
  printf '\n\033[1;90m(Hint: можно также сохранить в файл: wzprod --export /path/msg.md)\033[0m\n'
}

install_deps() {
  if ! command -v pkg >/dev/null 2>&1; then echo "Termux pkg недоступен"; exit 2; fi
  yes | pkg update || true
  yes | pkg install -y glow bat fzf || true
  printf '\033[1;92mУстановлены (если были доступны): glow, bat, fzf.\033[0m\n'
}

case "${1:-}" in
  --help|-h) usage ;;
  --version|-V) echo "wzprod 1.2.0" ;;
  --path) echo "$PROMPT_PATH" ;;
  --list) list_files ;;
  --pager) ensure_exists; less -R "$PROMPT_PATH" ;;
  --pretty) pretty_show ;;
  --menu) menu_pick ;;
  --copy) copy_clip ;;
  --export) shift; export_atomic "${1:-}" ;;
  --apply) shift; apply_helper "opt" "${1:-}" ;;
  --apply-exp) shift; apply_helper "opt ⚠️" "${1:-}" ;;
  --install-deps) install_deps ;;
  "" ) ensure_exists; cat "$PROMPT_PATH" ;;
  * ) printf 'Неизвестная опция: %s\n\n' "${1:-}" >&2; usage; exit 2 ;;
esac
