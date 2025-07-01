# 📦 WZ Utility Scripts — `scripts/utils/`

Служебные скрипты проекта **WheelZone**, используемые как вспомогательные модули в генераторах, CI, сборщиках отчётов и валидаторах.

---

## 🔧 `generate_metadata_block.sh`

> Версия: `v0.1`  
> Назначение: Генерация YAML или JSON метаданных на основе файла (обычно `.md`-отчётов `chatend`)  
> Статус: production-ready  
> Расположение: `scripts/utils/generate_metadata_block.sh`

### 📌 Возможности

- Поддержка `--file`, `--format yaml|json`, `--uuid-strategy content|random`
- Автоматическая генерация:
  - `uuid` (по содержимому или случайный)
  - `sha256` хеша
  - `slug` (на основе `SLUG:` в содержимом)
  - даты (`UTC ISO 8601`)
  - имени файла
  - генератора (с версией)
- Поддержка больших файлов (до 10MB)
- Надежная проверка ошибок и кроссплатформенность (`Linux`, `Termux`)
- Работает без `jq`, но поддерживает его для форматирования JSON (если установлен)

---

### 🧪 Примеры

```bash
# Базовый YAML-вывод
scripts/utils/generate_metadata_block.sh --file path/to/chat_2025-06-30_slug.md

# JSON формат
scripts/utils/generate_metadata_block.sh --file path/to/file.md --format json

# Случайный UUID
scripts/utils/generate_metadata_block.sh --file report.md --uuid-strategy random


---

📥 Аргументы

Аргумент	Описание

--file FILE	📌 Обязательный. Путь к обрабатываемому файлу
--format FORMAT	Формат вывода: yaml (по умолчанию) или json
--uuid-strategy	content (по содержимому, по умолчанию) или random
--help	Показать справку
--version	Показать версию скрипта



---

✅ Выходной формат

YAML:

---
uuid: 51d2c9c2-d9b3-57ea-9a0e-f3fbd8fcae38
slug: example_slug
filename: "chat_2025-06-30_example_slug.md"
date: "2025-06-30T18:22:47Z"
sha256: "4eec...82a"
generator: generate_metadata_block.sh v0.1
---

JSON:

{
  "uuid": "51d2c9c2-d9b3-57ea-9a0e-f3fbd8fcae38",
  "slug": "example_slug",
  "filename": "chat_2025-06-30_example_slug.md",
  "date": "2025-06-30T18:22:47Z",
  "sha256": "4eec...82a",
  "generator": "generate_metadata_block.sh v0.1"
}


---

📎 Зависимости

bash, sha256sum, uuidgen или python3

Опционально: jq (для красивого JSON-вывода)



---

🛡️ Безопасность и ограничения

Максимальный размер файла: 10MB

Проверка существования и читаемости файла

Автозамена невалидных UUID значением-заглушкой при сбоях

Очистка slug от спецсимволов, ограничение длины до 64 символов



---

🌐 Используется в:

wz_chatend.sh (в будущем)

chatend_summary_all.sh

chatend-meta (ядро WZChatEnds)

CI-интеграциях для валидации, сверки UUID/hash

Системе генерации core_status, meta-index, end_blocks



---

