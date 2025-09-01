#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:09+03:00-3843045824
# title: fix_Loki_log_entry_local_log.sh
# component: .
# updated_at: 2025-08-26T13:19:09+03:00

# 🔧 Fix v2: Улучшенное локальное логирование для Loki_log_entry.py

TARGET="$HOME/wheelzone-script-utils/scripts/Loki/Loki_log_entry.py"
BACKUP_DIR="$HOME/wheelzone-script-utils/backups"
BACKUP="$BACKUP_DIR/Loki_log_entry_$(date +%Y%m%d_%H%M%S).py"

# Создаем директорию для бэкапов
mkdir -p "$BACKUP_DIR"

# 1. Создаём бэкап с timestamp
echo "⏳ Создаём бэкап: $BACKUP"
cp "$TARGET" "$BACKUP" || {
    echo "❌ Ошибка при создании бэкапа"
    exit 1
}

# 2. Проверяем существование файла
if [[ ! -f "$TARGET" ]]; then
    echo "❌ Файл $TARGET не найден"
    exit 1
fi

# 3. Применяем изменения
cat > "$TARGET" <<'PYEOF'
#!/data/data/com.termux/files/usr/bin/python3
import json
import os
from datetime import datetime
import sys
import hashlib

# Конфигурация
LOG_DIR = os.path.expanduser("~/.wz_logs")
NOTION_LOG_FILE = os.path.join(LOG_DIR, "Loki_log.ndjson")
MOCK_RESPONSES = os.path.join(LOG_DIR, "Loki_mock_responses.ndjson")

# Создаём директории для логов
os.makedirs(LOG_DIR, exist_ok=True)

def generate_request_id(payload):
    """Генерирует уникальный ID для запроса"""
    payload_str = json.dumps(payload, sort_keys=True)
    return hashlib.md5(payload_str.encode()).hexdigest()

def log_locally(payload, response=None):
    """Логирует запрос и ответ в файл"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "request_id": generate_request_id(payload),
        "request": payload,
        "response": response
    }
    
    try:
        with open(NOTION_LOG_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
        
        if response:
            with open(MOCK_RESPONSES, "a", encoding="utf-8") as f:
                f.write(json.dumps(response, ensure_ascii=False) + "\n")
    except Exception as e:
        print(f"[WARNING] Ошибка локального логирования: {e}")

def Loki_log_entry(payload):
    """Основная функция логирования"""
    # Генерируем mock-ответ
    mock_response = {
        "status": "mocked",
        "request_id": generate_request_id(payload),
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Логируем запрос и ответ
    log_locally(payload, mock_response)
    
    if not os.getenv("NOTION_TOKEN") or not os.getenv("NOTION_LOG_DB_ID"):
        print("⚠️ NOTION_TOKEN или NOTION_LOG_DB_ID не установлены - используется локальное логирование")
        return mock_response
    
    # В реальной версии здесь будет вызов API Loki
    print("🔌 [MOCK] Запрос залогирован локально (тестовый режим)")
    return mock_response

if __name__ == "__main__":
    try:
        payload = json.load(sys.stdin)
        result = Loki_log_entry(payload)
        print(json.dumps(result))
    except json.JSONDecodeError:
        print('[ERROR] Неверный JSON-ввод')
        sys.exit(1)
    except Exception as e:
        print(f'[ERROR] Ошибка обработки: {e}')
        sys.exit(1)
PYEOF

# 4. Устанавливаем права
chmod +x "$TARGET"

# 5. Проверяем синтаксис
if ! python3 -c "import ast; ast.parse(open('$TARGET').read())"; then
    echo "❌ Ошибка синтаксиса в новом файле! Восстанавливаем бэкап..."
    cp "$BACKUP" "$TARGET"
    exit 1
fi

echo -e "\n✅ Автофикс успешно применён. Основные изменения:"
echo "  - Локальное логирование в ~/.wz_logs/Loki_log.ndjson"
echo "  - Mock-ответы в ~/.wz_logs/Loki_mock_responses.ndjson"
echo "  - Уникальные ID запросов"
echo "  - Проверка синтаксиса перед сохранением"
echo "  - Бэкап сохранён в $BACKUP"
