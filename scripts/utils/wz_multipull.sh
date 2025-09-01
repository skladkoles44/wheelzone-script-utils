#!/usr/bin/env bash
set -Eeuo pipefail
CFG="${1:-$HOME/wheelzone-script-utils/configs/repos.list}"

ok()  { printf "\033[1;92m[WZ]\033[0m %s\n" "$*"; }
err() { printf "\033[1;91m[ERR]\033[0m %s\n" "$*" >&2; }

[ -f "$CFG" ] || { err "Нет списка репо: $CFG"; exit 2; }

while IFS= read -r path; do
  # Пропускаем пустые/коммент
  [[ -z "$path" || "$path" =~ ^# ]] && continue
  if [ ! -d "$path/.git" ]; then
    err "Пропуск: не git-репо: $path"
    continue
  fi
  ok "→ Pull: $path"
  BR="$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  if ! git -C "$path" pull --rebase --autostash origin "$BR"; then
    err "pull --rebase не прошёл, fallback на обычный pull"
    git -C "$path" pull origin "$BR" || true
  fi

  # Если есть CLI-рефреш — запускаем
  if [ -x "$path/cli/wz-docs-refresh" ]; then
    ok "→ docs-refresh: $path"
    "$path/cli/wz-docs-refresh" || true
  else
    # Попробуем генератор/инсталлятор напрямую, если лежат как у wheelzone-script-utils
    [ -x "$path/scripts/utils/wz_gen_manpages.sh" ] && "$path/scripts/utils/wz_gen_manpages.sh" || true
    [ -x "$path/scripts/utils/wz_install_manpages.sh" ] && "$path/scripts/utils/wz_install_manpages.sh" || true
  fi
done < "$CFG"

ok "✓ multipull завершён"
