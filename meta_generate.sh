#!/data/data/com.termux/files/usr/bin/bash
# Сценарий генерации ядровых файлов управления WheelZone
# Версия: 1.0
# Автор: GPT
# Статус: implemented

mkdir -p ~/storage/downloads/project_44/MetaSystem

# architecture_map.yaml
cat <<ARCH > ~/storage/downloads/project_44/MetaSystem/architecture_map.yaml
frontend:
  framework: SvelteKit
  style: TailwindCSS
  features:
    - SSR
    - PWA
    - Mobile first

backend:
  language: Go
  structure:
    - REST API
    - Modular services

database:
  engine: MySQL
  tables:
    - suppliers
    - products
    - import_logs
ARCH

# project_dashboard.md
cat <<DASH > ~/storage/downloads/project_44/MetaSystem/project_dashboard.md
# WheelZone — Сводка проекта

## Архитектура
- Frontend: SvelteKit + Tailwind
- Backend: Go
- БД: MySQL

## Активные роли:
- Архитектор, Контр, Хакер, Кодер, Документатор, Тестировщик

## Meta-файлы:
- architecture_map.yaml
- interrole_matrix.json
- milestone_flags.json
- file_versions_index.json

## Последняя harmonize_all: [авто]
DASH

# interrole_matrix.json
cat <<ROLES > ~/storage/downloads/project_44/MetaSystem/interrole_matrix.json
{
  "архитектор": ["кодер", "контр"],
  "контр": ["архитектор", "хакер", "тестировщик"],
  "кодер": ["архитектор", "документатор"],
  "документатор": ["все"],
  "тестировщик": ["кодер"],
  "хакер": ["контр", "кодер"]
}
ROLES

# milestone_flags.json
cat <<MILE > ~/storage/downloads/project_44/MetaSystem/milestone_flags.json
{
  "architecture_defined": true,
  "db_structure_created": false,
  "first_api_ready": false,
  "frontend_base": false,
  "sync_integrated": false
}
MILE

# Хеш-фиксация
cd ~/storage/downloads/project_44/MetaSystem/
sha256sum architecture_map.yaml project_dashboard.md interrole_matrix.json milestone_flags.json > file_versions_index.json

