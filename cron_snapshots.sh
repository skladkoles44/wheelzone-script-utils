#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:54+03:00-4154164200
# title: cron_snapshots.sh
# component: .
# updated_at: 2025-08-26T13:19:54+03:00

export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin/applets:$PATH

cd ~/wheelzone/bootstrap_tool/

DATE=$(date +%Y-%m-%d)
RULES_SNAP=ALL/rules_auto/rules_snapshot_$DATE.md
PERSONAS_SNAP=ALL/personalities_auto/personas_snapshot_$DATE.md

# Снимки (примерные шаблоны - можно адаптировать)
echo "# WheelZone — Активные правила (Snapshot)" > "$RULES_SNAP"
echo "- Автоматическое правило 1" >> "$RULES_SNAP"
echo "- Автоматическое правило 2" >> "$RULES_SNAP"

echo "# WheelZone — GPT Личности (Snapshot)" > "$PERSONAS_SNAP"
echo "## /Стратег" >> "$PERSONAS_SNAP"
echo "## /Контр" >> "$PERSONAS_SNAP"

# Проверка изменений и git push
git add "$RULES_SNAP" "$PERSONAS_SNAP"
git diff --cached --quiet || (
  git commit -m "Авто-snapshot правил и GPT-личностей на $DATE"
  git push origin main
)
