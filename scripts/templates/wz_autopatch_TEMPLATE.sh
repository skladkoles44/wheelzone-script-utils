#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:33+03:00-4073731647
# title: wz_autopatch_TEMPLATE.sh
# component: .
# updated_at: 2025-08-26T13:19:33+03:00

set -euo pipefail
PATCH_FILE="${1:-$HOME/wzbuffer/tmp_patch/patch.diff}"
TARGET="${2:-$HOME/test_file.txt}"
TEST_STRING="patched"

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "[✗] Нет патча: $PATCH_FILE" >&2; exit 1
fi

echo "[⋯] Применение патча: $PATCH_FILE"
patch "$TARGET" "$PATCH_FILE" || exit 1

if grep -q "$TEST_STRING" "$TARGET"; then
  echo "[✓] Тест успешен: содержимое = '$TEST_STRING'"
else
  echo "[✗] Тест не пройден!" >&2; exit 2
fi

rm -f "$PATCH_FILE"
echo "[✓] Патч-файл удалён: $PATCH_FILE"
