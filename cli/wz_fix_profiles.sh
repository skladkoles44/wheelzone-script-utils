#!/data/data/com.termux/files/usr/bin/bash
# WZ Artifact Header v1.0
# Registry: wheelzone://cli/profiles/fix/v0.2.3
# Task-Class: idempotent
# Version: v0.2.3
# Owner: WheelZone
# Maintainer: WheelZone
# Created-At: 2025-09-25T00:00:00Z
# Updated-At: 2025-09-25T00:00:00Z
# Inputs: ~/.bashrc, ~/.bash_profile, ~/.zshrc
# Outputs: ~/wzbuffer/logs/profile_backups/, ~/wzbuffer/logs/wz_shell_profiles_fix.log
# Side-Effects: правки rc-файлов пользователя
# Idempotency: Yes; State-Markers: комментарии WZ:
# Run-Mode: dry-run|apply
# Rollback: авто-восстановление
# Compatibility: Termux Bash/Zsh (Android 15)

set -Eeuo pipefail
say(){ printf "\033[1;92m[WZ] %s\033[0m\n" "$1"; }
warn(){ printf "\033[1;33m[WZ] %s\033[0m\n" "$1"; }
err(){ printf "\033[1;31m[WZ] %s\033[0m\n" "$1"; }

MODE="apply"; [[ "${1:-}" == "--dry-run" ]] && MODE="dry-run"; say "Mode: $MODE"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOGDIR="$HOME/wzbuffer/logs"; BKDIR="$LOGDIR/profile_backups/$TS"; OUT="$LOGDIR/wz_shell_profiles_fix.log"
mkdir -p "$BKDIR" "$LOGDIR"

TARGETS=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc")

restore_from_backup(){
  warn "Ошибка. Авто-rollback из бэкапа: $BKDIR"
  for f in "${TARGETS[@]}"; do base="$(basename "$f")"; [[ -f "$BKDIR/$base" ]] && cp -a "$BKDIR/$base" "$f" && warn "Восстановлен: $f"; done
  err "Откат завершён."
}
trap restore_from_backup ERR

backup_file(){ local f="$1"; [[ -e "$f" ]] || return 0; cp -a "$f" "$BKDIR/$(basename "$f")"; }
crlf_to_lf(){ local f="$1"; [[ -f "$f" ]] || return 0; if grep -q $'\r' "$f"; then say "CRLF→LF: $f"; [[ "$MODE" == "dry-run" ]] || { tmp="$(mktemp)"; tr -d '\r' < "$f" > "$tmp" && cat "$tmp" > "$f"; rm -f "$tmp"; }; fi; }
safe_sed(){ local f="$1"; shift; [[ -f "$f" ]] || return 0; [[ "$MODE" == "dry-run" ]] && { say "SED(dry): $f | $*"; } || sed -i "$@" "$f"; }
write_file(){ local p="$1"; if [[ "$MODE" == "dry-run" ]]; then say "WRITE(dry): $p"; cat >/dev/null; else cat > "$p"; fi; }
append_file(){ local p="$1"; if [[ "$MODE" == "dry-run" ]]; then say "APPEND(dry): $p"; cat >/dev/null; else cat >> "$p"; fi; }

# --- Dedup: fix awk for BusyBox (avoid 'close' var, simple brace counting) ---
comment_function_duplicates(){
  local f="$1" name="$2"; [[ -f "$f" ]] || return 0
  local tmp="$(mktemp)"
  awk -v name="$name" '
    function is_func_start(s) { return (s ~ "^[[:space:]]*" name "[[:space:]]*\\(\\)[[:space:]]*\\{") }
    BEGIN{ total=0 }
    { lines[NR]=$0 }
    END{
      # Count total definitions
      for (i=1;i<=NR;i++) if (is_func_start(lines[i])) total++
      if (total<=1) { for(i=1;i<=NR;i++) print lines[i]; exit }
      # Walk and comment all but the last definition
      inblk=0; depth=0; seen=0
      for (i=1;i<=NR;i++){
        buf[i]=lines[i]
      }
      for (i=1;i<=NR;i++){
        line=lines[i]
        if (!inblk && is_func_start(line)) { inblk=1; depth=0; blk_start=i; seen++ }
        if (inblk){
          oc = gsub(/\{/, "{", line)
          cc = gsub(/}/, "}", line)
          depth += oc - cc
          if (depth<=0){
            if (seen < total){
              for (j=blk_start;j<=i;j++){
                # Не трогаем уже закомментированные строки
                if (buf[j] !~ /^[[:space:]]*#/) buf[j]="# WZ: disabled duplicate of " name " -> " buf[j]
              }
            }
            inblk=0
          }
        }
      }
      for (i=1;i<=NR;i++) print buf[i]
    }
  ' "$f" > "$tmp"
  if [[ "$MODE" == "dry-run" ]]; then say "DEDUP(dry): $f — функции: $name"; rm -f "$tmp"; else cat "$tmp" > "$f"; rm -f "$tmp"; fi
}

comment_alias_duplicates(){
  local f="$1" key="$2"; [[ -f "$f" ]] || return 0
  local tmp="$(mktemp)"
  awk -v key="$key" '
    BEGIN{ seen=0 }
    {
      if ($0 ~ "^[[:space:]]*alias[[:space:]]+" key "[[:space:]]*=") {
        seen++
        if (seen>1) { print "# WZ: disabled duplicate alias -> " $0; next }
      }
      print
    }
  ' "$f" > "$tmp"
  if [[ "$MODE" == "dry-run" ]]; then say "DEDUP-ALIAS(dry): $f — alias: $key"; rm -f "$tmp"; else cat "$tmp" > "$f"; rm -f "$tmp"; fi
}

# 1) backup
for f in "${TARGETS[@]}"; do backup_file "$f"; done; say "Бэкап создан: $BKDIR"

# 2) CRLF→LF
for f in "${TARGETS[@]}"; do crlf_to_lf "$f"; done

# 3) .bash_profile normalize
if [[ -f "$HOME/.bash_profile" ]]; then
  if ! grep -q 'WZ: normalized bash_profile' "$HOME/.bash_profile" 2>/dev/null; then
    write_file "$HOME/.bash_profile" <<'BPR'
# WZ: normalized bash_profile (single source of truth)
# Загружает ~/.bashrc для интерактивных bash-сессий.
if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ]; then
  [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi

# WZ: prefer per-user tmp cache
: "${TMPDIR:=$HOME/.cache}"
[ -d "$TMPDIR" ] || mkdir -p "$TMPDIR"; chmod 700 "$TMPDIR" 2>/dev/null || true

# WZ: normalized bash_profile
BPR
    say ".bash_profile нормализован"
  fi
else
  write_file "$HOME/.bash_profile" <<'BPR_NEW'
# WZ: normalized bash_profile (created)
if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ]; then
  [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi
BPR_NEW
  say ".bash_profile создан"
fi

# 4) .bashrc fixes
if [[ -f "$HOME/.bashrc" ]]; then
  # 4.1 alias gitpush → безопасный дефолт
  if grep -qE '^[[:space:]]*alias[[:space:]]+gitpush=' "$HOME/.bashrc"; then
    safe_sed "$HOME/.bashrc" -E 's|^[[:space:]]*alias[[:space:]]+gitpush=.*$|alias gitpush='\''git push'\''|g'
    say "alias gitpush → безопасный дефолт"
  fi
  # 4.2 feature-gate авто-SSH
  if ! grep -q 'WZ_NO_AUTO_SSH' "$HOME/.bashrc"; then
    if head -n 1 "$HOME/.bashrc" | grep -q '^#!'; then
      safe_sed "$HOME/.bashrc" '2a export WZ_NO_AUTO_SSH=1  # WZ: feature-gate auto-ssh menu (0=enable)'
    else
      safe_sed "$HOME/.bashrc" '1i export WZ_NO_AUTO_SSH=1  # WZ: feature-gate auto-ssh menu (0=enable)'
    fi
    say "Добавлен флаг WZ_NO_AUTO_SSH=1"
  fi
  # 4.3 запрет /sdcard/Download
  if grep -q '/sdcard/Download' "$HOME/.bashrc"; then
    safe_sed "$HOME/.bashrc" 's|^\(.*/sdcard/Download.*\)$|# WZ: ext storage disabled by policy -> ***REMOVED***|g'
    warn "Строки с /sdcard/Download закомментированы"
  fi
  # 4.4 канонический блок wz()/trend()/check
  if ! grep -q 'WZ: canonical wz() block' "$HOME/.bashrc"; then
    append_file "$HOME/.bashrc" <<'WZFUN'

# --- WZ: canonical wz() block (idempotent, no /sdcard) ---
wz() {
  echo "=== WZ Status @ $(date +'%Y-%m-%d %H:%M:%S') ==="
  local OUT
  OUT="$(
    [ -x "$HOME/wz_status.sh" ] && "$HOME/wz_status.sh" 2>/dev/null || echo "wz_status.sh not found"
  )"
  printf '\033[1;92m%s\033[0m\n' "$OUT"
  printf '%s\n' "$OUT" > "$HOME/wz_last_status.txt"
  {
    echo "=== $(date +'%Y-%m-%d %H:%M:%S') ==="
    printf '%s\n' "$OUT"
    echo
  } >> "$HOME/wz_status_log.txt"
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    ( printf '%s' "$OUT" | nohup termux-clipboard-set >/dev/null 2>&1 & ) >/dev/null 2>&1
  fi
}
wztrend() {
  local LOG="$HOME/wz_status_log.txt"
  [ -s "$LOG" ] || { echo "Нет лога: $LOG"; return 1; }
  echo "=== WZ Progress Trend (последние 10) ==="
  awk '
    /Progress: [0-9]+%/ {
      for (i=1;i<=NF;i++) if ($i ~ /[0-9]+%/) { gsub("%","",$i); p=$i }
      if (p!="") vals[n++]=p
    }
    END{
      if(n==0){ print "нет данных"; exit }
      start = (n>10)? n-10 : 0
      for(i=start;i<n;i++){
        barLen = int(vals[i]/5)
        bar=""; for(k=0;k<barLen;k++) bar=bar "#"
        printf("%2d) %3d%% | %s\n", i+1, vals[i], bar)
      }
      printf("\nТекущий прогресс: %d%%\n", vals[n-1])
    }
  ' "$LOG"
}
wzcheck() {
  local CUR PREV
  [ -f "$HOME/wz_last_status.txt" ] || { echo "нет статуса"; return 1; }
  CUR="$(grep -oE "Progress: [0-9]+%" "$HOME/wz_last_status.txt" 2>/dev/null | tail -n1 | grep -oE "[0-9]+" || echo 0)"
  PREV="$(grep -oE "Progress: [0-9]+%" "$HOME/wz_status_log.txt" 2>/dev/null | tail -n2 | head -n 1 | grep -oE "[0-9]+" || echo "$CUR")"
  [ -z "$CUR" ] && CUR=0
  [ -z "$PREV" ] && PREV="$CUR"
  if [ "$CUR" -lt "$PREV" ] && command -v termux-notification >/dev/null 2>&1; then
    termux-notification --title "WZ Rollout" --content "Прогресс просел: $PREV% → $CUR%" --priority high
  fi
  printf "Progress: %s%% (prev: %s%%)\n" "$CUR" "$PREV"
}
# --- WZ: canonical wz() block END ---
WZFUN
    say "Добавлен канонический блок wz()/trend()/check (без /sdcard)"
  fi
  # 4.5 дедуп функций
  comment_function_duplicates "$HOME/.bashrc" "wz"
  comment_function_duplicates "$HOME/.bashrc" "wztrend"
  comment_function_duplicates "$HOME/.bashrc" "wzcheck"
  # 4.6 дедуп алиасов
  comment_alias_duplicates "$HOME/.bashrc" "wzrec"
  comment_alias_duplicates "$HOME/.bashrc" "wzhist"
  comment_alias_duplicates "$HOME/.bashrc" "wzev"
else
  warn "~/.bashrc не найден — пропускаю фиксы .bashrc"
fi

# 5) .zshrc hygiene
if [[ -f "$HOME/.zshrc" ]]; then
  if ! grep -q 'WZ: normalized zshrc' "$HOME/.zshrc"; then
    HLINE="$(grep -E "source .*/\.hyperos_scripts/.*\.sh" "$HOME/.zshrc" | head -n 1 || true)"
    : "${HLINE:=# (no hyperos source found)}"
    write_file "$HOME/.zshrc" <<ZRC
# WZ: normalized zshrc
${HLINE}
export PATH="\$HOME/.local/bin:\$PATH"
# WZ: normalized zshrc
ZRC
    say ".zshrc нормализован"
  fi
fi

# 6) snapshot + clipboard verify
{
  echo "=== WheelZone: Profiles Fix Snapshot ==="
  echo "Timestamp (UTC): $TS"
  for f in "${TARGETS[@]}"; do
    [[ -f "$f" ]] || { echo "-----8<----- FILE: $f (NOT FOUND) -----"; echo; continue; }
    echo "-----8<----- FILE: $f -----"
    sha256sum "$f" | sed 's/^/SHA256: /'
    echo "SIZE: $(wc -c <"$f" 2>/dev/null || echo 0) bytes"
    echo "--- HEAD (first 10 lines) ---"; sed -n '1,10p' "$f"
    echo "--- TAIL (last 10 lines) ---"; tail -n 10 "$f" 2>/dev/null || true
    echo "-----8<----- END FILE: $f -----"; echo
  done
} > "$OUT"

if command -v termux-clipboard-set >/dev/null 2>&1; then
  if [[ "$MODE" == "dry-run" ]]; then
    say "Буфер(dry): пропущено"
  else
    termux-clipboard-set < "$OUT" || true
    if command -v termux-clipboard-get >/dev/null 2>&1; then
      head_out="$(head -c 256 "$OUT" | tr -d '\0')"
      head_cb="$(termux-clipboard-get 2>/dev/null | head -c 256 | tr -d '\0')"
      [[ "$head_out" == "$head_cb" ]] && say "Снимок и лог → буфер (верифицирован)" || warn "Буфер скопирован, но верификация не совпала"
    else
      warn "termux-clipboard-get не найден для верификации"
    fi
  fi
else
  warn "termux-api не найден: буфер пропущен (pkg install termux-api)"
fi

say "Готово. Mode=$MODE | Лог: $OUT | Бэкапы: $BKDIR"
