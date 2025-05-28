#!/data/data/com.termux/files/usr/bin/bash
cd ~/storage/downloads/project_44/MetaSystem/
echo "# WheelZone — Сводка проекта" > project_dashboard.md
echo "## Последнее обновление: $(date)" >> project_dashboard.md
echo "## Версионированные файлы:" >> project_dashboard.md
ls *.json *.md *.sh 2>/dev/null >> project_dashboard.md
