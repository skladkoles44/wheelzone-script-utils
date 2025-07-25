#!/data/data/com.termux/files/usr/bin/bash

cd ~/wheelzone/bootstrap_tool/ || exit 1
git checkout main || git switch main
git rebase --abort 2>/dev/null
rm -rf .git/rebase-merge 2>/dev/null
git pull --rebase origin main

# Добавляем все изменённые и новые файлы
git add .

# Проверка есть ли изменения
if ! git diff --cached --quiet; then
  NOW=$(date +"%Y-%m-%d %H:%M")
  git commit -m "Автопуш: изменения от $NOW"
  git push
else
  echo "[AutoPush] Нет новых файлов для фиксации."
fi

# === Проверка и запуск crond ===
if ! pgrep -x crond > /dev/null; then
  echo "[AutoFix] crond не запущен — запускаем..."
  crond -n &
else
  echo "[AutoFix] crond уже работает"
fi
