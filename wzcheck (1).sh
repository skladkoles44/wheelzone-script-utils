#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:18+03:00-3914632867
# title: wzcheck (1).sh
# component: .
# updated_at: 2025-08-26T13:20:19+03:00

echo "[wzcheck] Проверка состояния системы..."

PROOF_LOG=~/storage/downloads/project_44/MetaSystem/Logs/wzproof_issues.log

# Проверка: есть ли проблемы, выявленные wzproof
if grep -q '\[!\]' "$PROOF_LOG"; then
  echo "[!] Найдены проблемы в wzproof_issues.log:"
  grep '\[!\]' "$PROOF_LOG"
else
  echo "[wzcheck] wzproof: нарушений не выявлено."
fi

echo "[wzcheck] Проверка завершена."
