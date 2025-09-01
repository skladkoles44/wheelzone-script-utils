#!/data/data/com.termux/files/usr/bin/python3
import json
import os
from datetime import datetime
import sys

NOTION_TOKEN = os.getenv("NOTION_TOKEN")
NOTION_LOG_DB_ID = os.getenv("NOTION_LOG_DB_ID")
WZ_LOCAL_LOG = os.path.expanduser("~/.wz_logs/Loki_log.ndjson")
os.makedirs(os.path.dirname(WZ_LOCAL_LOG), exist_ok=True)

def log_locally(payload):
    payload["local_time"] = datetime.utcnow().isoformat()
    with open(WZ_LOCAL_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")

def Loki_log_entry(payload):
    log_locally(payload)

    if not NOTION_TOKEN or not NOTION_LOG_DB_ID:
        print("❌ NOTION_TOKEN or NOTION_LOG_DB_ID not set — лог записан только локально")
        return

    # Заглушка вместо отправки
    print("🔌 [MOCK] Логгер получил данные, но Loki API отключён в тестовом режиме")

if __name__ == "__main__":
    try:
        payload = json.load(sys.stdin)
        Loki_log_entry(payload)
    except Exception as e:
        print(f"[ERROR] Неверный JSON или ошибка логгера: {e}")
        sys.exit(1)
