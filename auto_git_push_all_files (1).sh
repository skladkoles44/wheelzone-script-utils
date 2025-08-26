# uuid: 2025-08-26T13:19:49+03:00-896256644
# title: auto_git_push_all_files (1).sh
# component: .
# updated_at: 2025-08-26T13:19:49+03:00


#!/data/data/com.termux/files/usr/bin/bash
cd ~/wheelzone/bootstrap_tool/

# Обновление ветки
git checkout main >/dev/null 2>&1
git pull --rebase origin main >/dev/null 2>&1

# Проверка любых изменений
if [ -n "$(git status --porcelain)" ]; then
  git add . 2>/dev/null
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
  git commit -m "AutoPush при запуске Termux: фикс всех изменений от $TIMESTAMP"
  git push
else
  echo "[AutoPush] Нет новых файлов для фиксации."
fi
