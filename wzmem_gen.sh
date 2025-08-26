#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:19+03:00-1126309402
# title: wzmem_gen.sh
# component: .
# updated_at: 2025-08-26T13:20:19+03:00

# Генерация файла WZ_Memory_Structure.txt

out_path="$HOME/storage/downloads/project_44/Termux/WZ_Memory_Structure.txt"

mkdir -p "$(dirname "$out_path")"

cat <<EOF > "$out_path"
# WZ_Memory_Structure.md

**Дата генерации:** $(date '+%Y-%m-%d %H:%M:%S')

---

## 1. Execution Environment

- **Основная платформа:** Termux на Android
- **Дополнительная среда:** Windows 10 (редко, только браузер)
- **Рабочие папки Termux:**
  - ~/storage/downloads/project_44/Termux/ — основная директория
  - ~/storage/downloads/project_44/Termux/Script/ — скрипты
- **Alias по умолчанию:** wzpanel, gptsync_auto, vzstart, vzstop
- **Cron, логирование, спиннеры** — включены для всех длительных команд (git, rclone, find, jq, curl, и др.)

---

## 2. Storage Layer

- GitHub: auto-framework, bootstrap_tool, wheelzone-core, skladkoles-backend
- Google Drive: gdrive:lllBackUplll-WheelZone
- Яндекс.Диск: yandex_wheelzone:/lllBackUplll-WheelZone/
- Резервные форматы: .md, .txt, .jsonl

---

## 3. Personas

- /стратег — логика, архитектура
- /контр — аудит, критика
- /хакер — защита, маскировка
- /кодер — реализация, API
- Все активны, самообучаются, взаимодействуют

---

## 4. Auto-Rules & Frameworks

- gptsync: автообработка
- autopush v4: массовый пуш, quarantine
- sandbox:/ → ~/storage/downloads/
- auto-framework: ядро логики
- bootstrap_tool: резерв, cron

---

## 5. Smart Memory Features

- Auto-learning
- Memory Snapshots (в планах)
- Conflict Resolver
- Auto-Audit Trigger
- wzmem: просмотр памяти

---

## 6. Примеры файлов

- WZ_*.md/.txt — системные
- linked_profiles_44.jsonl
- vin_success_log.jsonl
- gpt_active_rules.md

---

## 7. Защита

- valuable: true — защита от удаления
- Карантин: Quarantine/deleted/
- >50MB — пометка
EOF

less "$out_path"
