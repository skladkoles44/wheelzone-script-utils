#!/data/data/com.termux/files/usr/bin/bash
set -eo pipefail

echo "⚙️ Запуск финализации ядра WZ и массовой регистрации правил..."

# 📌 Пути
CORE_YAML="$HOME/wz-wiki/core/core.yaml"
REGISTRY="$HOME/wz-wiki/registry/registry.yaml"
HISTORY="$HOME/wz-wiki/registry/core_history.yaml"
LOG_CSV="$HOME/wz-wiki/logs/script_event_log.csv"
GENERATOR="$HOME/wheelzone-script-utils/scripts/utils/generate_core_docs.sh"

# ✅ Генерация документации ядра (если генератор существует)
if [ -f "$GENERATOR" ]; then
    echo "📚 Генерация документации core.yaml..."
    bash "$GENERATOR"
else
    echo "⚠️ Скрипт генерации не найден: $GENERATOR"
fi

# 🧠 Логирование события
python3 ~/wheelzone-script-utils/scripts/utils/fractal_logger.py \
  --title "Финализация ядра WZ и генерация core-документации" \
  --type core \
  --details "README_core.md, layers/*.md, modules/*.md созданы из core.yaml" \
  --principles self_correction self_documenting atomic_write

# 🧾 Git commit
cd ~/wz-wiki
git add "$REGISTRY" "$HISTORY" docs/core/
git commit -m "chore: финализация ядра WZ, история + лог + документация core.yaml"
git push

echo "✅ Завершено. Проверь:"
echo "- $HISTORY"
echo "- $REGISTRY"
echo "- ~/wz-wiki/docs/core/"
