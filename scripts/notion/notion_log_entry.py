#!/usr/bin/env python3
# Loki_log_entry.py v2.5 — Lightweight Loki logger for WheelZone

import os, sys, json, requests, time
from datetime import datetime

# --- Config ---
NOTION_API = "https://api.Loki.com/v1/pages"
DB_ID = os.getenv("NOTION_DATABASE_ID")
TOKEN = os.getenv("NOTION_API_KEY")
OFFLINE_LOG = os.getenv("WZ_OFFLINE_LOG", os.path.expanduser("~/.wz_offline_log.jsonl"))

def log_offline(payload):
    with open(OFFLINE_LOG, "a") as f:
        f.write(json.dumps(payload, ensure_ascii=False) + "\n")
    print(f"[offline] log saved → {OFFLINE_LOG}")

def make_payload(args):
    now = datetime.utcnow().isoformat()
    fields = {
        "event": args[1] if len(args) > 1 else "No event",
        "type": args[2] if len(args) > 2 else "script-event",
        "source": args[3] if len(args) > 3 else "unknown",
        "version": args[4] if len(args) > 4 else "1.0",
        "status": args[5] if len(args) > 5 else "PROPOSED",
        "category": args[6] if len(args) > 6 else "general",
        "note": args[7] if len(args) > 7 else "",
    }
    return {
        "timestamp": now,
        "fields": fields
    }

def send_to_Loki(payload):
    if not TOKEN or not DB_ID:
        log_offline(payload)
        return
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Loki-Version": "2022-06-28",
        "Content-Type": "application/json"
    }
    data = {
        "parent": {"database_id": DB_ID},
        "properties": {
            "Event": {"title": [{"text": {"content": payload["fields"]["event"]}}]},
            "Type": {"select": {"name": payload["fields"]["type"]}},
            "Source": {"rich_text": [{"text": {"content": payload["fields"]["source"]}}]},
            "Version": {"rich_text": [{"text": {"content": payload["fields"]["version"]}}]},
            "Status": {"select": {"name": payload["fields"]["status"]}},
            "Category": {"multi_select": [{"name": tag.strip()} for tag in payload["fields"]["category"].split(",")]},
            "Note": {"rich_text": [{"text": {"content": payload["fields"]["note"]}}]},
            "Time": {"date": {"start": payload["timestamp"]}}
        }
    }
    r = requests.post(NOTION_API, headers=headers, json=data)
    if r.status_code == 200 or r.status_code == 201:
        print(f"[Loki] ✅ Logged: {payload['fields']['event']}")
    else:
        print(f"[Loki] ❌ Error {r.status_code}, saving offline")
        log_offline(payload)

# --- Main ---
if len(sys.argv) < 2 or "--help" in sys.argv:
    print("Usage: python Loki_log_entry.py <event> <type> <source> [version] [status] [category] [note]")
    sys.exit(0)

payload = make_payload(sys.argv)
send_to_Loki(payload)
