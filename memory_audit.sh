#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:11+03:00-1440455556
# title: memory_audit.sh
# component: .
# updated_at: 2025-08-26T13:20:11+03:00


echo "=== GPT MEMORY AUDIT ==="
echo
echo ">> Активные директории:"
ls -d ~/wheelzone/* ~/storage/downloads/project_44/Termux/* 2>/dev/null | grep -v '\.sh$'

echo
echo ">> Проверка .bashrc и alias:"
grep wzpanel ~/.bashrc || echo "⚠ Alias wzpanel не найден"
grep auto-framework ~/.bashrc | head -n 1

echo
echo ">> Проверка Git-реп:"
cd ~/wheelzone/auto-framework || exit 1
git remote -v
git status -s

echo
echo ">> Персональные правила:"
grep -i "в рамочку" ~/wheelzone/auto-framework/ALL/rules/*.md | cut -d: -f1 | sort -u

echo
echo "=== Аудит завершён ==="
