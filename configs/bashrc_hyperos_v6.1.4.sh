#!/data/data/com.termux/files/usr/bin/bash
# ~/.bashrc — WZ Termux Core v6.1.4 (HyperOS safe & stable)

# ========== ПЕРЕМЕННЫЕ ==========
export TMPDIR="$HOME/.cache"
export WZ_LOGDIR="$HOME/.wz_logs"
export HISTFILE="$WZ_LOGDIR/.bash_history"
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL="ignorespace:ignoredups"
export EDITOR="nano"
export LC_ALL="en_US.UTF-8"

# ========== ИНИЦИАЛИЗАЦИЯ ==========
mkdir -p "$TMPDIR" "$WZ_LOGDIR"

# ========== ЛОГ СТАРТА ==========
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Termux session (v6.1.4)" >> "$WZ_LOGDIR/session_audit.log"

# ========== WZ CORE ==========
if [ -x "$HOME/wheelzone-script-utils/core/hyperos_core.sh" ]; then
  bash "$HOME/wheelzone-script-utils/core/hyperos_core.sh" --armor >> "$WZ_LOGDIR/wz_core.log" 2>&1 &
fi

# ========== TERMUX NOTIFICATION ==========
if command -v termux-notification >/dev/null 2>&1; then
  termux-notification \
    --title "📟 Termux готов" \
    --content "WZ Core запущен — $(date '+%H:%M:%S')" \
    --priority low \
    --id "wz_startup" \
    --button1 "Повторить" \
    --button1-action "bash $HOME/wheelzone-script-utils/core/hyperos_core.sh" &
fi

# ========== WZ LOG EVENT ==========
if [ -x "$HOME/wheelzone-script-utils/scripts/logging/wz_log_event.sh" ]; then
  "$HOME/wheelzone-script-utils/scripts/logging/wz_log_event.sh" \
    --type system --severity info \
    --title "✅ Termux session started" \
    --message "PID: $$ @ $(date '+%F %T')" &
fi

# ========== ПОДАВЛЕНИЕ МУСОРА ОТ ФОНОВ ==========
disown -a

# ========== PROMPT ==========
PS1='\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '

# ========== МОДУЛИ ==========
for mod in "$HOME/wheelzone-script-utils/configs/bashrc_mod/"*.sh; do
  [ -f "$mod" ] && source "$mod"
done

# ========== АВТООЧИСТКА ==========
cleanup() {
  termux-wake-unlock 2>/dev/null
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Session closed (PID $$)" >> "$WZ_LOGDIR/session_audit.log"
}
trap cleanup EXIT
