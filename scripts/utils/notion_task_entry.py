#!/data/data/com.termux/files/usr/bin/python3
import argparse
import json
import logging
import os
import sys
from datetime import datetime, timezone

from dotenv import load_dotenv
from notion_client import Client

# === Логгер ===
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%SZ",
)

# === CLI ===
parser = argparse.ArgumentParser(description="📌 Добавление задачи в Notion")
parser.add_argument("name", help="Имя задачи")
parser.add_argument(
    "--status", default="TODO", choices=["TODO", "In Progress", "Done"], help="Статус"
)
parser.add_argument(
    "--priority",
    default="Medium",
    choices=["Low", "Medium", "High", "Critical"],
    help="Приоритет",
)
parser.add_argument("--tags", nargs="*", default=[], help="Список тегов")
parser.add_argument("--source", default="manual", help="Источник задачи")
parser.add_argument("--dry-run", action="store_true", help="Не отправлять в Notion")
parser.add_argument(
    "--verbose", action="store_true", help="Показать отправляемые данные"
)
args = parser.parse_args()

# === Загрузка конфигурации ===
try:
    load_dotenv(os.path.expanduser("~/wheelzone-script-utils/configs/.env.notion"))
    NOTION_TOKEN = os.environ["NOTION_TOKEN"]
    DATABASE_ID = os.environ["TASKS_DATABASE_ID"]
except Exception as e:
    logging.critical("❌ Ошибка загрузки .env или переменных окружения: %s", str(e))
    sys.exit(1)

notion = Client(auth=NOTION_TOKEN)


# === Функция добавления задачи ===
def add_task():
    if not args.name.strip():
        logging.error("❌ Имя задачи не может быть пустым")
        return

    now = datetime.now(timezone.utc).isoformat()

    payload = {
        "parent": {"database_id": DATABASE_ID},
        "properties": {
            "Name": {"title": [{"text": {"content": args.name.strip()}}]},
            "Status": {"select": {"name": args.status}},
            "Priority": {"select": {"name": args.priority}},
            "Tags": {"multi_select": [{"name": tag} for tag in args.tags]},
            "Source": {"select": {"name": args.source}},
            "Created": {"date": {"start": now}},
        },
    }

    if args.verbose or args.dry_run:
        print("📦 Payload:")
        print(json.dumps(payload, indent=2, ensure_ascii=False))

    if args.dry_run:
        logging.info("🔍 Dry run: задача не отправлена")
        return

    try:
        res = notion.pages.create(**payload)
        logging.info(
            "✅ Задача добавлена: %s [%s/%s] → %s",
            args.name,
            args.status,
            args.priority,
            res.get("id"),
        )
    except Exception as e:
        logging.exception("❌ Ошибка при отправке в Notion")


# === Запуск ===
if __name__ == "__main__":
    add_task()
