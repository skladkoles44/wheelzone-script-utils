#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
export LC_ALL=C

OUTDIR="$HOME/storage/downloads"
CLIP="/data/data/com.termux/files/usr/bin/termux-clipboard-set"
CLIP_GET="/data/data/com.termux/files/usr/bin/termux-clipboard-get"

# 1) Запускаем runner
RPT="$("$HOME/wz_prod_opt_runner.sh" | tail -n1)"
[ -f "$RPT" ] || { echo "[ERR] нет отчёта: $RPT"; exit 1; }

# 2) Скопируем в буфер (если доступен)
if [ -x "$CLIP" ]; then
  if "$CLIP" < "$RPT" >/dev/null 2>&1; then
    echo "[OK] Отчёт скопирован в буфер"
  else
    echo "[WARN] не удалось скопировать в буфер"
  fi
fi

# 3) Покажем короткий summary (первые 40 строк)
echo "=== HEAD(40) of $RPT ==="
sed -n '1,40p' "$RPT"

# 4) Подсказка + пауза
echo "[DONE] Полный отчёт: $RPT"
echo "Нажми Enter для выхода..."
read _
