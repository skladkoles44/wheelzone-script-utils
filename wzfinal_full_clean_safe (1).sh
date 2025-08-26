#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:19+03:00-2629100862
# title: wzfinal_full_clean_safe (1).sh
# component: .
# updated_at: 2025-08-26T13:20:19+03:00

echo "[0/5] Инициализация среды..."
bash ~/bin/wzinit.sh

echo "[0.5/5] Проверка на скрытые символы..."
bash ~/bin/wzproof.sh

# 1. Обновление file_versions_index.json
echo "[1/5] Обновление file_versions_index.json..."
find ~/storage/downloads/project_44/ \( -name '*.sh' -o -name '*.json' -o -name '*.go' -o -name '*.md' \) -exec sha256sum {} \; > ~/storage/downloads/project_44/MetaSystem/file_versions_index.json

# 2. Перегенерация project_dashboard.md
echo "[2/5] Перегенерация project_dashboard.md..."
bash ~/storage/downloads/project_44/MetaSystem/Scripts/dashboard_autogen.sh

# 3. Проверка валидности GPT_state.json
echo "[3/5] Проверка валидности GPT_state.json..."
jq . ~/storage/downloads/project_44/MetaSystem/GPT_state.json > /dev/null || echo "[!] GPT_state.json INVALID"

# 4. Harmonize all
echo "[4/5] Harmonize all..."
bash ~/bin/harmonize_all.sh

# 5. Gatekeeper + Git push
echo "[5/5] Проверка gatekeeper и Git push..."
bash ~/storage/downloads/project_44/MetaSystem/release_gatekeeper.sh && bash ~/bin/git_push_WZ_all.sh || echo "[!] Push отменён gatekeeper'ом"

# Завершение
echo "[wzfinal] Завершение всех незаконченных дел..."
bash ~/bin/alias_restore.sh
