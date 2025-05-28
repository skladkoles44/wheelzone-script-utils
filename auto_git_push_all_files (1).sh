
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
