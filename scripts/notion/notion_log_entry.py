#!/data/data/com.termux/files/usr/bin/python3
import json
import os
from datetime import datetime
from datetime import timezone
import sys
import hashlib

# Конфигурация
LOG_DIR = os.path.expanduser("~/.wz_logs")
NOTION_LOG_FILE = os.path.join(LOG_DIR, "notion_log.ndjson")
MOCK_RESPONSES = os.path.join(LOG_DIR, "notion_mock_responses.ndjson")

# Создаём директории для логов
os.makedirs(LOG_DIR, exist_ok=True)

def generate_request_id(payload):
    """Генерирует уникальный ID для запроса"""
    payload_str = json.dumps(payload, sort_keys=True)
    return hashlib.md5(payload_str.encode()).hexdigest()

def log_locally(payload, response=None):
    """Логирует запрос и ответ в файл"""
    log_entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
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

def notion_log_entry(payload):
    """Основная функция логирования"""
    # Генерируем mock-ответ
    mock_response = {
        "status": "mocked",
        "request_id": generate_request_id(payload),
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
    
    # Логируем запрос и ответ
    log_locally(payload, mock_response)
    
    if not os.getenv("NOTION_TOKEN") or not os.getenv("NOTION_LOG_DB_ID"):
        print("⚠️ NOTION_TOKEN или NOTION_LOG_DB_ID не установлены - используется локальное логирование")
        return mock_response
    
    # В реальной версии здесь будет вызов API Notion
    print("🔌 [MOCK] Запрос залогирован локально (тестовый режим)")
    return mock_response

if __name__ == "__main__":
    try:
        payload = json.load(sys.stdin)
        result = notion_log_entry(payload)
        print(json.dumps(result))
    except json.JSONDecodeError:
        print('[ERROR] Неверный JSON-ввод')
        sys.exit(1)
    except Exception as e:
        print(f'[ERROR] Ошибка обработки: {e}')
        sys.exit(1)
