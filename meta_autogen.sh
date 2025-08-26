#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:11+03:00-3535680727
# title: meta_autogen.sh
# component: .
# updated_at: 2025-08-26T13:20:11+03:00

# Полная генерация управляющих meta-файлов WheelZone
# Версия: 2.0
cd ~/storage/downloads/project_44/MetaSystem/

# release_gatekeeper.sh
cat <<'GATE' > release_gatekeeper.sh
#!/bin/bash
# Проверка консистентности перед git/rclone push
echo "[GATEKEEPER] Проверка..."
if grep -q planned file_versions_index.json; then
  echo "ОШИБКА: Есть незавершённые файлы (status: planned). Прекращаю."
  exit 1
fi
echo "[GATEKEEPER] Все проверки пройдены. Продолжайте."
exit 0
GATE
chmod +x release_gatekeeper.sh

# rules_index.json
cat <<'RULES' > rules_index.json
{
  "@file_hash_tracking": true,
  "@auto_versioning": true,
  "@project_status": "draft_design_mode",
  "@runtime_status": "offline",
  "@meta_generate_standard": "enforced",
  "@dashboard_sync": true,
  "@kontur_mode": "passive_observer",
  "@secure_file_creation": "Termux_insert_only"
}
RULES

# remotes.json
cat <<'REMOTES' > remotes.json
{
  "go": "https://github.com/skladkoles44/wheelzone-go-core",
  "legacy_py": "https://github.com/skladkoles44/skladkoles-backend"
}
REMOTES

# version_map.json
cat <<'VMAP' > version_map.json
{
  "MetaSystem": {
    "architecture_map.yaml": "v1",
    "project_dashboard.md": "v1",
    "interrole_matrix.json": "v1",
    "milestone_flags.json": "v1"
  }
}
VMAP

# account_meta_versions.json
cat <<'META' > account_meta_versions.json
{
  "roles": {
    "архитектор": "v3.0",
    "контр": "v2.2",
    "кодер": "v4.0",
    "хакер": "v4.2"
  },
  "core_files": {
    "project_dashboard.md": "v1",
    "rules_index.json": "v1",
    "remotes.json": "v1"
  }
}
META

# rules_matrix.md
cat <<'MATRIX' > rules_matrix.md
# Сводная матрица правил WheelZone

| Правило                      | Дата         | Область        | Источник     |
|-----------------------------|--------------|----------------|--------------|
| @file_hash_tracking         | авто         | Фиксация       | GPT          |
| @auto_versioning            | авто         | Версионирование| GPT          |
| @project_status             | 2025-05-18   | Архитектура    | Архитектор   |
| @dashboard_sync             | 2025-05-18   | Навигация      | Архитектор   |
| @kontur_mode                | 2025-05-18   | Аналитика      | Контр        |
| @meta_generate_standard     | 2025-05-18   | Создание       | GPT          |
MATRIX

# Пересчёт хешей
sha256sum *.sh *.json *.md > file_versions_index.json
