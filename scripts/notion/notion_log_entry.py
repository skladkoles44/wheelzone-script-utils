#!/data/data/com.termux/files/usr/bin/env python3
# Notion Logger CLI v2.3 — Финальная проверенная версия для WheelZone

import os, sys, argparse, json, requests
from datetime import datetime

NOTION_TOKEN = os.getenv("NOTION_API_TOKEN") or os.getenv("NOTION_TOKEN")
NOTION_DB = os.getenv("NOTION_LOG_DB_ID")

# Кешируем константы
NOTION_HEADERS = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
} if NOTION_TOKEN else None
NOTION_URL = "https://api.notion.com/v1/pages"

def log(msg): print(f"[LOG] {msg}", file=sys.stderr)

def get_iso_timestamp():
    return datetime.utcnow().isoformat(timespec='seconds') + "Z"

def post_to_notion(payload):
    if not NOTION_HEADERS:
        raise ValueError("Notion token not configured")
    r = requests.post(NOTION_URL, headers=NOTION_HEADERS, json=payload)
    r.raise_for_status()

def main():
    if not NOTION_TOKEN or not NOTION_DB:
        log("❌ NOTION_TOKEN or NOTION_LOG_DB_ID not set")
        sys.exit(1)

    parser = argparse.ArgumentParser()
    parser.add_argument("--type", required=True)
    parser.add_argument("--severity", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--message", required=True)
    args = parser.parse_args()

    payload = {
        "parent": { "database_id": NOTION_DB },
        "properties": {
            "Name": { "title": [{ "text": { "content": args.title } }] },
            "Message": { "rich_text": [{ "text": { "content": args.message } }] },
            "Type": { "select": { "name": args.type } },
            "Severity": { "select": { "name": args.severity } },
            "Timestamp": { "date": { "start": get_iso_timestamp() } }
        }
    }

    post_to_notion(payload)
    log("✅ Log sent to Notion")

if __name__ == "__main__":
    main()
