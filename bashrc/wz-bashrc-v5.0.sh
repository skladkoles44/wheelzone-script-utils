# uuid: 2025-08-26T13:19:50+03:00-916623717
# title: wz-bashrc-v5.0.sh
# component: bashrc
# updated_at: 2025-08-26T13:19:50+03:00

# ~/.bashrc — WheelZone Termux v5.1

# 🛡 Предотвращение повторной инициализации
if [ "$WZ_BASHRC_INIT" = "1" ]; then
  return
fi
export WZ_BASHRC_INIT=1

# 🧠 WheelZone приветствие
echo -e "\033[1;36m=== 🧠 WheelZone Termux Initialized ===\033[0m"
echo "Доступные команды:"
echo "  wzcleaner  - Очистка системы"
echo "  wzhealth   - Диагностика окружения"
echo "  wzsync     - Git-синхронизация"
echo "  wzsecure   - Безопасный режим"
echo "  end        - Завершение сессии"
echo "  wzhelp     - Помощь по WZ"

# 📁 Пути и переменные
export PATH="$HOME/bin:$PATH"
export WZ_DIR="$HOME/wz-wiki"
export WZ_BUFFER="$HOME/wzbuffer"
export TERMUX_API_HOME="$HOME/.termux"

# ✅ Алиасы
alias l='ls -lh'
alias la='ls -lAh'
alias ll='ls -lah'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpull='git pull'
alias ..='cd ..'
alias ...='cd ../..'
alias wzcleaner='bash $WZ_DIR/tools/servirovochnaya/wz_cron_trim.sh'
alias wzhealth='bash $WZ_DIR/tools/wz_healthcheck.sh'
alias wzsync='bash $WZ_DIR/tools/wz_sync_rules.sh'
alias wzsecure='bash $WZ_DIR/tools/wz_secure_mode.sh'
alias end='bash $WZ_DIR/tools/chatend/wz_chatend.sh'
alias wzhelp='cat $WZ_DIR/docs/termux_help.txt 2>/dev/null || echo "Документация недоступна."'

# ⚙️ Автообслуживание Termux (в фоне)
termux-auto-maintenance() {
  sleep 15
  echo "[WZ] ⏳ Автообслуживание началось..." >> ~/.last_termux_update.log
  pkg update -y && pkg upgrade -y
  apt update && apt upgrade -y
  pip list | grep -v '^-e' | cut -d ' ' -f1 | xargs pip install --upgrade
  npm update -g --silent || echo "[!] npm update failed"
  cargo install-update -a 2>/dev/null
  go get -u all 2>/dev/null
  echo "[WZ] ✅ Завершено: $(date)" >> ~/.last_termux_update.log
}
termux-auto-maintenance &

# 🔐 Подключение helpers.sh
if [ -f "/usr/local/lib/wzchatend/helpers.sh" ]; then
  source /usr/local/lib/wzchatend/helpers.sh
else
  echo "[WARN] Helpers.sh не найден" >&2
fi

# 📦 Гарантия директорий
mkdir -p "$WZ_BUFFER" "$HOME/bin"

# 🔁 Автосинхронизация .bashrc из wz-configs
if [ -f "$HOME/bin/wz_sync_bashrc.sh" ]; then
  bash "$HOME/bin/wz_sync_bashrc.sh" &
fi

# ✅ Финализация
echo -e "\033[1;36m=== 🧠 WheelZone Termux Ready ===\033[0m"
