#!/data/data/com.termux/files/usr/bin/bash
echo "[alias_restore] Восстановление ключевых алиасов..."

ALIASES=(
  "wzfinal='bash ~/bin/wzfinal_full.sh'"
  "wz='bash ~/bin/harmonize_all.sh'"
  "wzpanel='bash ~/bin/wzpanel'"
  "wzvps='ssh root@89.111.171.170'"
  "gptsync='bash ~/bin/gptsync_auto.sh'"
  "wzchaos='bash ~/bin/wzchaos.sh'"
  "wzproof='bash ~/bin/wzproof.sh'"
  "alias_restore='bash ~/bin/alias_restore.sh'"
)

for entry in "${ALIASES[@]}"; do
  key=$(echo "$entry" | cut -d'=' -f1)
  grep -qxF "alias $entry" ~/.bashrc || echo "alias $entry" >> ~/.bashrc
done

source ~/.bashrc
echo "[alias_restore] Готово."
