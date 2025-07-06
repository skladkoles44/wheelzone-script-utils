import os
import datetime
import json
import logging
from notion_client import Client, APIResponseError
from dotenv import load_dotenv

load_dotenv(os.path.expanduser("~/wheelzone-script-utils/configs/.env.notion"))

notion = Client(auth=os.getenv("NOTION_TOKEN"))
database_id = os.getenv("DATABASE_ID")

logging.basicConfig(
    format='%(message)s',
    level=logging.INFO,
)

def log_entry(name, log_type="System", status="INFO"):
    if not all(isinstance(x, str) for x in [name, log_type, status]):
        raise ValueError("All log fields must be strings.")

    now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")

    try:
        response = notion.pages.create(
            parent={"database_id": database_id},
            properties={
                "Name": {"title": [{"text": {"content": name}}]},
                "Type": {"select": {"name": log_type}},
                "Status": {"select": {"name": status}},
                "Time": {"rich_text": [{"text": {"content": now}}]},
            }
        )
        logging.info(json.dumps({
            "level": "INFO",
            "event": "notion_log",
            "name": name,
            "type": log_type,
            "status": status,
            "timestamp": now,
            "id": response.get("id")
        }))
    except APIResponseError as e:
        logging.error(json.dumps({
            "level": "ERROR",
            "event": "notion_log",
            "msg": str(e),
            "timestamp": now
        }))

if __name__ == "__main__":
    log_entry("🔧 Initial test from Termux", "System", "OK")
