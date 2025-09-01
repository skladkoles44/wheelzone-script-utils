---
fractal_uuid: e6189905-518a-4d88-9ced-35ef27d044ab
---
# 🔒 Permalog: WheelZone Permanent Logging Standard

**Permalog** — это стратегия *гарантированной фиксации* любого важного действия во всех слоях системы:
- Git (коммиты, push)
- Loki (через `Loki_log_entry.py`)
- YAML-реестр (`registry/permalog_registry.yaml`)
- Лог-файл (`logs/permalog.log`)
- CI-интеграции (через флаг `--permalog`)

Цель — избавиться от ручных тапов и создать самофиксирующуюся архитектуру.

## Примеры фиксации:
- `wz_notify.sh --permalog ...`
- Автоматическое логирование правил в `wz_sync_rules.sh`
- Логирование chatend в `wzdrone_chatend.sh`

## Статус: ✅ Активировано
