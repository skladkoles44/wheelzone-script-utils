#!/data/data/com.termux/files/usr/bin/bash
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
