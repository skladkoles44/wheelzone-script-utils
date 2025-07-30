#!/data/data/com.termux/files/usr/bin/bash
# WZ Agent Bootstrapper (GPT-Agent v1.0)
set -euo pipefail

echo "[WZ-Agent] Инициализация агентного режима..."

# Подгружаем окружение и логгер
source ~/wheelzone-script-utils/scripts/notion/wz_notify.sh --source agent-init

# Логируем запуск
~/wheelzone-script-utils/scripts/logging/wz_log_event.sh \
  --type agent --title "🤖 Агент GPT активирован" \
  --message "Запущен режим агентного управления в среде WheelZone (Termux)" --commit

# Добавим автозагрузку (если нужно)
grep -q "gpt_agent_wz.sh" ~/.bashrc || echo '~/wheelzone-script-utils/agents/gpt_agent_wz.sh' >> ~/.bashrc

echo "[WZ-Agent] Готово. Режим агента активен."
