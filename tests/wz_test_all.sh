#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:46+03:00-1286515721
# title: wz_test_all.sh
# component: .
# updated_at: 2025-08-26T13:19:46+03:00

set -eo pipefail
logfile="$HOME/.wz_logs/test_results.log"
echo "=== Тестирование всех скриптов: $(date) ===" > "$logfile"
errors=0

for script in "$HOME/wheelzone-script-utils/scripts/utils/"*.sh; do
  if grep -q "# --testable" "$script"; then
    echo "[🔧] Тест: $(basename "$script")" | tee -a "$logfile"
    if bash "$script" --test >> "$logfile" 2>&1; then
      echo "✅ PASS: $script" | tee -a "$logfile"
    else
      echo "❌ FAIL: $script" | tee -a "$logfile"
      errors=$((errors + 1))
    fi
  fi
done

if (( errors > 0 )); then
  termux-notification --title "WZ Tests Failed" --content "$errors ошибок в тестах"
  exit 1
else
  echo "[✓] Все тесты прошли успешно"
  termux-notification --title "WZ Test" --content "✅ Все тесты прошли успешно"
fi
