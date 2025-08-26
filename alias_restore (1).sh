#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:47+03:00-2453232859
# title: alias_restore (1).sh
# component: .
# updated_at: 2025-08-26T13:19:47+03:00

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
