#!/data/data/com.termux/files/usr/bin/bash
# [WZ] Восстановление ключевых alias в ~/.bashrc, если они отсутствуют

BASHRC="$HOME/.bashrc"
NEEDED_ALIASES=(
"alias wzfinal='bash ~/bin/wzfinal_full.sh'"
"alias wzchaos='bash ~/bin/wzchaos.sh'"
"alias wzpanel='bash ~/bin/wzpanel'"
"alias sanitize='bash ~/bin/sanitize.sh'"
"alias gptsync='bash ~/bin/gptsync_auto.sh'"
"alias wzpush='bash ~/bin/git_push_WZ_all.sh'"
)

for entry in "${NEEDED_ALIASES[@]}"; do
    grep -qxF "$entry" "$BASHRC" || echo "$entry" >> "$BASHRC"
done

echo "[alias_restore] Проверка завершена. Все alias восстановлены."
