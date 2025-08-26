#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:27+03:00-964645541
# title: install_bashrc.sh
# component: .
# updated_at: 2025-08-26T13:19:27+03:00

# install_bashrc.sh — Установка WZ .bashrc v6.1 (HyperOS / Termux)

set -euo pipefail
IFS=$'\n\t'

readonly BASHRC_TARGET="$HOME/.bashrc"
readonly BACKUP_PATH="$HOME/.bashrc.backup.$(date +%s)"
readonly WZ_LOGDIR="$HOME/.wz_logs"
readonly INSTALL_TAG="[WZ-INIT]"

echo "$INSTALL_TAG 🛠️ Установка .bashrc v6.1"
echo "$INSTALL_TAG 🔒 Создание бэкапа: $BACKUP_PATH"
cp "$BASHRC_TARGET" "$BACKUP_PATH" 2>/dev/null || touch "$BASHRC_TARGET"

mkdir -p "$WZ_LOGDIR"

cat > "$BASHRC_TARGET" <<'EOB'
#!/data/data/com.termux/files/usr/bin/bash
# ~/.bashrc — WZ Termux Core v6.1 (модульная архитектура)

# ========== БАЗОВАЯ БЕЗОПАСНОСТЬ ==========
umask 077
set -o noclobber
set -o pipefail
shopt -s nocaseglob

# ========== OOM ЗАЩИТА + ПРИОРИТЕТ ==========
adjust_oom() {
  if [ -w /proc/$$/oom_score_adj ]; then
    echo -1000 > /proc/$$/oom_score_adj 2>/dev/null
  elif [ -w /proc/$$/oom_adj ]; then
    echo -17 > /proc/$$/oom_adj 2>/dev/null
  fi
  renice -n 19 -p $$ >/dev/null 2>&1 || true
}
adjust_oom

# ========== ПЕРЕМЕННЫЕ СРЕДЫ ==========
export TMPDIR="$HOME/.cache"
export WZ_LOGDIR="$HOME/.wz_logs"
export HISTFILE="$WZ_LOGDIR/.bash_history"
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL="ignorespace:ignoredups"
export EDITOR="nano -w"
export LC_ALL="en_US.UTF-8"

# ========== ИНИЦИАЛИЗАЦИЯ ==========
mkdir -p "$TMPDIR" "$WZ_LOGDIR" 2>/dev/null

# ========== ЛОГИРОВАНИЕ ==========
exec 2>>"$WZ_LOGDIR/hyperos_errors.log"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Session started (PID $$)" >> "$WZ_LOGDIR/session_audit.log"

# ========== WZ CORE START ==========
if [ -x "$HOME/wheelzone-script-utils/core/hyperos_core.sh" ]; then
  bash "$HOME/wheelzone-script-utils/core/hyperos_core.sh" --armor >> "$WZ_LOGDIR/wz_core.log" 2>&1 &
  disown
fi

# ========== TERMUX NOTIFICATION ==========
if command -v termux-notification &>/dev/null; then
  termux-notification \
    --title "📟 Termux инициализирован" \
    --content "WZ Core готов — $(date '+%H:%M:%S')" \
    --priority low \
    --id "wz_startup" \
    --button1 "Открыть core" \
    --button1-action "bash $HOME/wheelzone-script-utils/core/hyperos_core.sh" &
fi

# ========== ЛОГГЕР WZ (если есть) ==========
if [ -x "$HOME/wheelzone-script-utils/scripts/logging/wz_log_event.sh" ]; then
  "$HOME/wheelzone-script-utils/scripts/logging/wz_log_event.sh" \
    --type system --severity info \
    --title "🚀 Termux session started" \
    --message "bashrc PID: $$, time: $(date '+%F %T')" &
fi

# ========== PROMPT ==========
PS1='\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '

# ========== МОДУЛИ ==========
for mod in "$HOME/wheelzone-script-utils/configs/bashrc_mod/"*.sh; do
  [ -f "$mod" ] && source "$mod"
done

# ========== АВТООЧИСТКА ==========
cleanup() {
  termux-wake-unlock 2>/dev/null
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session closed (PID $$)" >> "$WZ_LOGDIR/session_audit.log"
}
trap cleanup EXIT
EOB

echo "$INSTALL_TAG ✅ Установка завершена. Применяем..."
exec bash
