#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:24+03:00-2447811328
# title: wz_chatend_md_report.sh
# component: .
# updated_at: 2025-08-26T13:19:24+03:00

# WZ ChatEnd MD Report v1.0 — прогон через MD-прокси + отчёт (safe/fractal)
set -Eeuo pipefail

SAFE_LOG="$HOME/.wz_logs/wz_chatend_safe.log"
FRAC_LOG="$HOME/.wz_logs/fractal_chatend.log"
RPT="$HOME/wzbuffer/wz_chatend_quick_report.txt"
PROXY="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend_md_proxy.sh"

usage(){
  echo "Usage: $(basename "$0") <input.md>"
  echo "Runs MD-proxy on the file, then builds a quick report and copies it to clipboard."
}

[ $# -eq 1 ] || { usage; exit 1; }
IN="$1"
[ -f "$IN" ] || { echo "[ERR] input not found: $IN" >&2; exit 2; }
[ -x "$PROXY" ] || { echo "[ERR] proxy not found: $PROXY" >&2; exit 2; }

mkdir -p "$(dirname "$SAFE_LOG")" "$(dirname "$FRAC_LOG")" "$(dirname "$RPT")"

# Чистим только хвостовой контекст для наглядности
: > "$SAFE_LOG" 2>/dev/null || true
: > "$FRAC_LOG" 2>/dev/null || true

# Прогон через MD-прокси
"$PROXY" "$IN" || true

# Сбор отчёта
{
  echo "=== WZ ChatEnd Quick Report @$(date -u +'%Y-%m-%d %H:%M:%S') Z ==="
  echo "[i] PROXY: $PROXY"
  echo "[i] INPUT: $IN"
  echo "--- safe.tail (12) ---"
  tail -n 12 "$SAFE_LOG" 2>/dev/null || echo "<empty>"
  echo "--- fractal.tail (120) ---"
  tail -n 120 "$FRAC_LOG" 2>/dev/null || echo "<empty>"
  echo "--- anomalies (:/, :~, :\$HOME) ---"
  tail -n 200 "$FRAC_LOG" 2>/dev/null \
    | grep -nE '(^|[^:]):/(home|data|sdcard|storage)|:~|:\$HOME' || echo "<none>"
  echo "--- nofile ('Не найден файл') ---"
  tail -n 200 "$FRAC_LOG" 2>/dev/null \
    | grep -n 'Не найден файл' || echo "<none>"
} | tee "$RPT" >/dev/null

command -v termux-clipboard-set >/dev/null 2>&1 && termux-clipboard-set < "$RPT" 2>/dev/null || true
echo "[i] Report saved: $RPT (копирован в буфер, если доступен termux-clipboard-set)"
