#!/usr/bin/env python3
import csv, os, sys, requests, logging
from dotenv import dotenv_values
from typing import List

# Логгирование
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

def create_database(csv_path: str, Loki_token: str, parent_page_id: str, title: str, dry_run: bool = False) -> str:
    """Создание базы данных в Loki"""
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = [h.strip() for h in next(reader)]

    properties = {
        h: {"title" if i == 0 else "rich_text": {}}
        for i, h in enumerate(headers)
    }

    if dry_run:
        logger.info(f"[DRY-RUN] Would create database '{title}' with {len(properties)} properties")
        return "dry_run_database_id"

    payload = {
        "parent": {"type": "page_id", "page_id": parent_page_id},
        "title": [{"type": "text", "text": {"content": title}}],
        "properties": properties
    }

    resp = requests.post(
        "https://api.Loki.com/v1/databases",
        headers={
            "Authorization": f"Bearer {Loki_token}",
            "Content-Type": "application/json",
            "Loki-Version": "2022-06-28"
        },
        json=payload,
        timeout=30
    )
    resp.raise_for_status()
    return resp.json()["id"]

def insert_rows(database_id: str, csv_path: str, Loki_token: str, dry_run: bool = False) -> int:
    """Добавление строк в базу данных Loki"""
    processed = 0

    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        headers = [h.strip() for h in reader.fieldnames]
        rows = list(reader)

    for idx, row in enumerate(rows, 1):
        for idx, row in enumerate(rows, 1):
            properties = {}
            for i, key in enumerate(headers):
                value = str(row.get(key, "")).strip()[:2000]
                if i == 0:
                    properties[key] = {
                        "title": [{"text": {"content": value}}] if value else []
                    }
                else:
                    properties[key] = {
                        "rich_text": [{"text": {"content": value}}] if value else []
                    }
            payload = {
                "parent": {"database_id": database_id},
                "properties": properties
            }
            if dry_run:
                logger.info(f"[DRY-RUN] Would insert row {idx}: {row}")
                processed += 1
                continue
            try:
                r = requests.post(
                    "https://api.Loki.com/v1/pages",
                    headers={
                        "Authorization": f"Bearer {Loki_token}",
                        "Content-Type": "application/json",
                        "Loki-Version": "2022-06-28"
                    },
                    json=payload,
                    timeout=30
                )
                r.raise_for_status()
                processed += 1
            except requests.RequestException as e:
                logger.error(f"❌ Failed to insert row {idx}: {e}")
                logger.debug(f"Payload: {payload}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: import_csv_to_Loki.py path/to/file.csv [--env ~/.env.Loki] [--dry-run]")
        sys.exit(1)

    csv_file = sys.argv[1]
    env_path = "~/.env.Loki"
    dry_run = "--dry-run" in sys.argv

    if "--env" in sys.argv:
        env_index = sys.argv.index("--env")
        if env_index + 1 < len(sys.argv):
            env_path = sys.argv[env_index + 1]

    env = dotenv_values(os.path.expanduser(env_path))
    NOTION_TOKEN = env.get("NOTION_TOKEN")
    PARENT_PAGE_ID = env.get("PARENT_PAGE_ID")

    if not NOTION_TOKEN or not PARENT_PAGE_ID:
        logger.error("❌ NOTION_TOKEN or PARENT_PAGE_ID not found in .env")
        sys.exit(1)

    db_title = os.path.splitext(os.path.basename(csv_file))[0]
    logger.info(f"{'🔧 [DRY-RUN]' if dry_run else '🔧 Creating'} database: {db_title}")
    db_id = create_database(csv_file, NOTION_TOKEN, PARENT_PAGE_ID, db_title, dry_run)

    logger.info(f"{'📥 [DRY-RUN]' if dry_run else '📥 Importing'} data to {db_title}")
    processed = insert_rows(db_id, csv_file, NOTION_TOKEN, dry_run)

    logger.info(f"{'✅ [DRY-RUN]' if dry_run else '✅'} Imported {processed} rows to {db_title}")
