# 🔒 Permalog: WheelZone Permanent Logging Standard

**Permalog** — это стратегия *гарантированной фиксации* любого важного действия во всех слоях системы:
- Git (коммиты, push)
- Notion (через `notion_log_entry.py`)
- YAML-реестр (`registry/permalog_registry.yaml`)
- Лог-файл (`logs/permalog.log`)
- CI-интеграции (через флаг `--permalog`)

Цель — избавиться от ручных тапов и создать самофиксирующуюся архитектуру.

## Примеры фиксации:
- `wz_notify.sh --permalog ...`
- Автоматическое логирование правил в `wz_sync_rules.sh`
- Логирование chatend в `wzdrone_chatend.sh`

## Статус: ✅ Активировано
