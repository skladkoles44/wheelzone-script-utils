#!/data/data/com.termux/files/usr/bin/bash
# WheelZone CLI — Core Bootstrap Checker

echo "🔍 Проверка ядра WheelZone..."

check() {
  [[ -f "$1" ]] && echo "✅ Найдено: $1" || echo "❌ Отсутствует: $1"
}

check "$HOME/wz-wiki/logs/core_history.csv"
check "$HOME/wz-wiki/mnemosyne/mnemosyne_index.yaml"
check "$HOME/wz-wiki/registry/chatends.yaml"
check "$HOME/wz-wiki/rules/core_boot_rule.md"
check "$HOME/wheelzone-script-utils/scripts/logging/wz_log_event.sh"
check "$HOME/wheelzone-script-utils/bin/core_history.sh"
check "$HOME/wheelzone-script-utils/bin/wz_mnemosyne.sh"

echo "📦 Инициализация завершена"
