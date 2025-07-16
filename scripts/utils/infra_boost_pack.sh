#!/data/data/com.termux/files/usr/bin/bash

set -e

# 🚀 [0/10] Запуск HyperOS ядра
CORE=~/wheelzone-script-utils/core/hyperos_core.sh
chmod +x "$CORE"
"$CORE" --armor &
echo "✅ Ядро HyperOS запущено в фоне."


echo "🚀 [1/10] Добавление CI badge в README..."
REPO=~/wz-wiki
BADGE='[![CI](https://drone.wheelzone.ai/api/badges/wz-wiki/status.svg)](https://drone.wheelzone.ai/wz-wiki)'
grep -q "$BADGE" "$REPO/README.md" || echo -e "\n$BADGE" >> "$REPO/README.md"

echo "✅ CI badge вставлен."

echo "🚀 [2/10] Проверка наличия Drone job на rules/"
DRONE_FILE="$REPO/.drone.yml"
RULE_JOB=$(grep -A2 "rules/" "$DRONE_FILE" | grep check_rule.sh || true)
if [[ -z "$RULE_JOB" ]]; then
cat >> "$DRONE_FILE" <<'BLOCK'

- name: check rules
  image: bash
  commands:
    - ./scripts/utils/check_rule.sh
  when:
    changes:
      - rules/**
BLOCK
echo "✅ CI проверка правил добавлена."
else
echo "⚠️ Проверка уже есть."
fi

echo "🚀 [3/10] Установка мониторинговых утилит..."
pkg install -y htop net-tools ripgrep fzf tmux > /dev/null

echo "✅ Установлено: glances, vnstat, ripgrep, fzf, tmux"

echo "🚀 [4/10] Связка ChatEnd ↔ ChatLog"
CHATEND_SH=~/wheelzone-script-utils/scripts/wz_chatend.sh
grep -q 'chatlog_path:' "$CHATEND_SH" || sed -i '/^echo "insights_file:/a echo "chatlog_path: chatlog/$(basename "$CHAT_FILE")" >> "$END_FILE"' "$CHATEND_SH"

echo "✅ Связь chatlog добавлена."

echo "🚀 [5/10] Синхронизация WZChatEnds/"
cd "$REPO"
git add WZChatEnds/
git commit -m "docs: sync WZChatEnds" || echo "⚠️ Нечего коммитить"
git push || echo "⚠️ Push не выполнен"

echo "🚀 [6/10] Обновление registry.yaml"
REG="$REPO/registry/registry.yaml"
grep -q 'infra_boost_pack.sh' "$REG" || echo "- script: scripts/utils/infra_boost_pack.sh" >> "$REG"

echo "✅ Обновлён реестр."

echo "🚀 [7/10] Добавление wz_notify в CI"
NOTIFY_LINE='./scripts/notion/wz_notify.sh --type ci --title "ChatEnd complete" --permalog'
grep -q "$NOTIFY_LINE" "$DRONE_FILE" || echo "
- name: notify chatend
  image: bash
  commands:
    - $NOTIFY_LINE" >> "$DRONE_FILE"

echo "✅ wz_notify.sh вставлен."

echo "🚀 [8/10] Создание README_infra.md"
mkdir -p "$REPO/docs/architecture/"
cat > "$REPO/docs/architecture/README_infra.md" <<DOC
# 🌐 WheelZone Infrastructure Overview

- VPS:
  - Sapphire Holmium — prod backend + Drone
  - Yellow Hydrogenium — dev/test + runner
  - Sorting Node — архив + runner

- GitHub: wz-wiki, wheelzone-script-utils
- Termux: Android CLI
- CI: Drone CI + auto ChatEnd + rules
- Логгирование: chatend_summary.csv, todo.csv, script_log.csv
DOC

git add "$REPO/docs/architecture/README_infra.md"
git commit -m "docs: добавлен инфраструктурный README" || echo "⚠️ Уже был"
git push || echo "⚠️ Push не выполнен"

echo "🚀 [9/10] Стопы для резервного копирования"
mkdir -p ~/wzbuffer/backup_stop
echo '/storage/emulated/0/sort /storage/emulated/0/backup' > ~/wzbuffer/backup_stop/paths.txt

echo "✅ Путь для бэкапов готов."

echo "🚀 [10/10] Финализация"
echo "🎉 Скрипт завершён. Всё готово к следующему этапу."
~/wheelzone-script-utils/scripts/notion/wz_notify.sh --type ci --title "infra_boost_pack завершён"
