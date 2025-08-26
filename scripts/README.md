#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:12+03:00-2342359703
# title: README.md
# component: scripts
# updated_at: 2025-08-26T13:20:12+03:00

#!/data/data/com.termux/files/usr/bin/python3
# wz_ai_rule.sh — WheelZone AI Rule Interface v3.1

CLI-интерфейс генерации технических правил через OpenRouter AI. Автоматически регистрирует правило в YAML, кеширует ответы, делает git commit/push. Не требует ключа API — работает с pk-anon.

## 🚀 Команды

## 🧰 Зависимости
- curl
- python3
- uuidgen
- git
- pip: [pyyaml]

## 📁 Пути
  cache: ~/.cache/wz_ai/
  registry: ~/wz-knowledge/registry.yaml
  rules_dir: ~/wz-knowledge/rules/
  log_file: ~/.cache/wz_ai/ai_rule.log

## 👤 Автор
WheelZone AI Interface
