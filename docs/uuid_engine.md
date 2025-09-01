---
fractal_uuid: ae355440-8c20-4b91-be60-6389838db5d8
---
# 🧬 UUID Engine (v4.1.2)

**Описание:**  
Кастомный генератор UUID, реализованный на Python. Поддерживает разные форматы (`--slug`, `--quantum`, `--time`, `--both`) и централизует `SESSION_ID` для всей системы WheelZone.

## 📂 Расположение
`scripts/utils/generate_uuid.py`

## 🛠️ Поддерживаемые флаги

| Аргумент     | Описание                                               |
|--------------|--------------------------------------------------------|
| `--slug`     | Первые 8 символов UUID                                 |
| `--quantum`  | Формат `uuid-YYYYMMDDHHMMSS-xxxxxx`                    |
| `--time`     | Дата + укороченный UUID                                |
| `--both`     | JSON с `uuid` и `session_id`                           |
| *ничего*     | Стандартный UUID (по умолчанию `uuid4`)               |

## 🧪 Примеры
```bash
python3 generate_uuid.py --quantum
python3 generate_uuid.py --both

🧱 Стандартизация

Все скрипты используют переменную:

export SESSION_ID="${SESSION_ID:-$(python3 ~/wheelzone-script-utils/scripts/utils/generate_uuid.py --slug)}"

