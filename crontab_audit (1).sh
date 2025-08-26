#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:54+03:00-2591219673
# title: crontab_audit (1).sh
# component: .
# updated_at: 2025-08-26T13:19:54+03:00

# [WZ] Аудит crontab: дубли + пустые команды
OUT="$HOME/storage/downloads/project_44/MetaSystem/Logs/cron_audit.log"
NOTES="$HOME/storage/downloads/project_44/MetaSystem/kontrol_notes.md"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "$OUT")"

echo "=== [CRONTAB AUDIT] $DATE ===" >> "$OUT"

# Считаем количество дубликатов
dupes=$(crontab -l | sort | uniq -d)
if [[ -n "$dupes" ]]; then
    echo "[!] Найдены дубликаты:" >> "$OUT"
    echo "$dupes" >> "$OUT"
    echo "- crontab содержит дубликаты заданий — проверь" >> "$NOTES"
fi

# Проверка на пустые команды
crontab -l | awk '{if(NF < 6) print "[!] Пустая или неполная команда: " $0}' >> "$OUT"

echo "" >> "$OUT"
