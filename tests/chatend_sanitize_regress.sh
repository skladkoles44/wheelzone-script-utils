#!/data/data/com.termux/files/usr/bin/bash
# WZ ChatEnd Sanitize Regression (local) v1.0
set -Eeuo pipefail

SAFE="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_safe.sh"
FLOG="$HOME/.wz_logs/fractal_chatend.log"
SLOG="$HOME/.wz_logs/wz_chatend_safe.log"
OUT="$HOME/.wz_tmp/chatend_regress_report.txt"

# 1) Подготовка тестовых файлов (3 варианта Include)
mkdir -p "$HOME/wzbuffer/chatend_test"
cat > "$HOME/wzbuffer/chatend_test/nested.md" <<'MD'
# Nested
Content OK
MD
cat > "$HOME/wzbuffer/chatend_test/main_space.md" <<'MD'
# Main
Include: ~/wzbuffer/chatend_test/nested.md
MD
cat > "$HOME/wzbuffer/chatend_test/main_nospace.md" <<'MD'
# Main
Include:~/wzbuffer/chatend_test/nested.md
MD
cat > "$HOME/wzbuffer/chatend_test/main_homevar.md" <<'MD'
# Main
Include:$HOME/wzbuffer/chatend_test/nested.md
MD

# 2) Чистим фрактальный лог и прогоняем без exec (сеанс не роняем)
: > "$FLOG" || true
if [ -x "$SAFE" ]; then
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main_space.md" || true
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main_nospace.md" || true
  "$SAFE" --verbose --no-exec --auto "$HOME/wzbuffer/chatend_test/main_homevar.md" || true
else
  echo "[ERR] safe wrapper not executable: $SAFE" >&2
  exit 2
fi

# 3) Анализ логов
SAFE_TAIL="$(tail -n 10 "$SLOG" 2>/dev/null || true)"
FRAC_TAIL="$(tail -n 120 "$FLOG" 2>/dev/null || true)"
ANOM="$(printf "%s\n" "$FRAC_TAIL" | grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME' || true)"
NOFILE="$(printf "%s\n" "$FRAC_TAIL" | grep -n 'Не найден файл' || true)"

STATUS="OK"
[ -n "$ANOM" ] && STATUS="FAIL"
[ -n "$NOFILE" ] && STATUS="FAIL"

{
  echo "=== ChatEnd Sanitize Regress @$(date -u +%F' '%T)Z ==="
  echo "[status] $STATUS"
  echo "[safe.tail]"; printf "%s\n" "${SAFE_TAIL:-<none>}"
  echo "[anomalies]"; if [ -n "$ANOM" ]; then printf "%s\n" "$ANOM"; else echo "<none>"; fi
  echo "[nofile]";   if [ -n "$NOFILE" ]; then printf "%s\n" "$NOFILE"; else echo "<none>"; fi
} | tee "$OUT"

# Возвращаем 0/1 для автоматизаций
[ "$STATUS" = "OK" ]
