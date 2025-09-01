#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
LEN="${1:-24}"
[[ "$LEN" =~ ^[0-9]+$ ]] || { echo "[WZ] Длина должна быть числом"; exit 2; }
(( LEN >= 16 && LEN <= 64 )) || { echo "[WZ] Длина 16..64"; exit 2; }
allow='A-Za-z0-9!@#$%^&*()_+\-=\[\]{};:,<.>/?'
has_all_classes(){ # stdin -> 0/1
  local s; s="$(cat)"
  grep -q '[A-Z]' <<<"$s" && grep -q '[a-z]' <<<"$s" && \
  grep -q '[0-9]' <<<"$s" && grep -q '[!@#$%^&*()_+\-=\[\]{};:,<.>/?]' <<<"$s"
}
gen(){
  # берём лишний запас, фильтруем по allow, режем до LEN
  tr -dc "$allow" < <(openssl rand -base64 $((LEN*3/2+8))) | head -c "$LEN"
}
pass=""
for i in {1..20}; do
  pass="$(gen)"
  if has_all_classes <<<"$pass"; then break; fi
done
[[ -n "$pass" ]] || { echo "[WZ] Не удалось сгенерировать подходящий пароль"; exit 1; }

# выводим и логируем
printf '%s\n' "$pass"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","event":"passgen","len":%d}\n' "$ts" "$LEN" >> "$HOME/wzbuffer/logs/passgen_log.ndjson"

# кладём во временный файл с правами 600 (для ручного копирования в KeePassDX)
tmpf="$HOME/wzbuffer/last_pass.txt"
printf '%s\n' "$pass" > "$tmpf"
chmod 600 "$tmpf"

# копия в буфер, если есть termux-clipboard-set
if command -v termux-clipboard-set >/dev/null 2>&1; then
  printf '%s' "$pass" | termux-clipboard-set || true
fi
