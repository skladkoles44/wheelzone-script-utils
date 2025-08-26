#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:40+03:00-4197890992
# title: test_wz_chatend_after_patch.sh
# component: .
# updated_at: 2025-08-26T13:19:40+03:00

set -Eeuo pipefail

# 0) Алиас chatend и тестовые файлы
. "$HOME/.termux/aliases.sh" 2>/dev/null || true
if ! command -v chatend >/dev/null 2>&1; then
  grep -vE '^(alias chatend=)' "$HOME/.termux/aliases.sh" > "$HOME/.termux/aliases.tmp" 2>/dev/null || true
  cat >> "$HOME/.termux/aliases.tmp" <<'EAA'
alias chatend='$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh --verbose'
EAA
  mv -f "$HOME/.termux/aliases.tmp" "$HOME/.termux/aliases.sh"
  . "$HOME/.termux/aliases.sh" 2>/dev/null || true
fi

mkdir -p "$HOME/wzbuffer/chatend_test"
[ -f "$HOME/wzbuffer/chatend_test/main.md" ] || cat > "$HOME/wzbuffer/chatend_test/main.md" <<'MD1'
# Main
Include: ~/wzbuffer/chatend_test/nested.md
MD1
[ -f "$HOME/wzbuffer/chatend_test/nested.md" ] || cat > "$HOME/wzbuffer/chatend_test/nested.md" <<'MD2'
# Nested
Content OK
MD2

# 1) Прогон: БЕЗ exec, чтобы не ронять сессию
if command -v chatend >/dev/null 2>&1; then
  chatend --no-exec --auto "$HOME/wzbuffer/chatend_test/main.md" || true
else
  bash "$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main.md" || true
fi

# 2) Краткий отчёт
REPORT="$HOME/.wz_tmp/chatend_sanitize_report.txt"
{
  echo "=== WZ ChatEnd Sanitize Report (@$(date -u +%F\ %T)Z) ==="
  echo
  echo "--- safe wrapper (tail 10) ---"
  tail -n 10 "$HOME/.wz_logs/wz_chatend_safe.log" 2>/dev/null || echo "[i] no safe log yet"

  echo
  echo "--- fractal anomalies (':/' & ':~') last 120 lines ---"
  tail -n 120 "$HOME/.wz_logs/fractal_chatend.log" 2>/dev/null | \
    grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:\~' || echo "[OK] нет детектов ':/' ':~' в последних 120 строках"

  echo
  echo "--- recent 'Не найден файл' (tail filtered, last 10) ---"
  tail -n 200 "$HOME/.wz_logs/fractal_chatend.log" 2>/dev/null | \
    grep -n "Не найден файл" | tail -n 10 || echo "[i] нет записей 'Не найден файл' в последних 200 строках"
} > "$REPORT"

# 3) Копирование в буфер
if command -v termux-clipboard-set >/dev/null 2>&1; then
  termux-clipboard-set < "$REPORT" && echo "[OK] Отчёт скопирован в буфер: $REPORT"
else
  echo "[WARN] termux-clipboard-set не найден; смотри файл: $REPORT"
fi
