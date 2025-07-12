#!/data/data/com.termux/files/usr/bin/python3
#!/data/data/com.termux/files/usr/bin/python3
# 📛 File: notion.py
# 🧠 Purpose: Send log events (like diagram generation) to a Notion database
# 🔐 Requires: NOTION_TOKEN and DATABASE_ID
# 📦 Версия: 2.3.0-prod (WZ hardened, full)

import hashlib
import json
import os
import sys
from datetime import datetime

import requests

__all__ = ["log_diagram_snapshot"]

from datetime import datetime, timezone


def UTC_TIMESTAMP():

    return (
        datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    )


def envload(var: str, required=True, default=None) -> str:
    val = os.environ.get(var, default)
    if required and not val:
        raise EnvironmentError(f"Missing required environment variable: {var}")
    return val


NOTION_TOKEN = envload("NOTION_TOKEN")
DATABASE_ID = envload(
    "DATABASE_ID", required=False, default="cdf2a47c-8803-8153-989b-00031f18f337"
)


def get_headers():
    return {
        "Authorization": f"Bearer {NOTION_TOKEN}",
        "Content-Type": "application/json",
        "Notion-Version": "2022-06-28",
    }


def log(level: str, msg: str, **extra):
    print(
        {
            "level": level,
            "ts": UTC_TIMESTAMP(),
            "event": "notion_log",
            "msg": msg,
            **extra,
        }
    )


def compute_sha(path):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return "n/a"


def validate_payload(data: dict):
    if not isinstance(data, dict):
        raise TypeError("Input must be a dictionary")
    if not {"title", "files"}.issubset(data):
        raise ValueError("Missing required keys: 'title', 'files'")


def log_diagram_snapshot(data: dict):
    validate_payload(data)

    first_file = next(iter(data.get("files", [])), None)
    if first_file and not data.get("sha"):
        data["sha"] = compute_sha(first_file)

    payload = {
        "parent": {"database_id": DATABASE_ID},
        "properties": {
            "Name": {"title": [{"text": {"content": data["title"]}}]},
            "Timestamp": {"date": {"start": data.get("timestamp", UTC_TIMESTAMP())}},
            "Script": {
                "rich_text": [{"text": {"content": data.get("script") or "unknown"}}]
            },
            "SHA": {"rich_text": [{"text": {"content": data.get("sha", "n/a")}}]},
            "Files": {
                "rich_text": [{"text": {"content": ", ".join(data.get("files", []))}}]
            },
        },
    }

    res = requests.post(
        "https://api.notion.com/v1/pages",
        headers=get_headers(),
        json=payload,
        timeout=10,
    )
    res.raise_for_status()
    log("INFO", f"Created page: {data.get('title')}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as f:
            payload = json.load(f)
    else:
        payload = {
            "title": "Тестовая запись из wz_generate_diagram",
            "files": ["docs/architecture/git_repository_tree.md"],
            "script": "manual-test",
            "timestamp": UTC_TIMESTAMP(),
        }

    try:
        log_diagram_snapshot(payload)
    except Exception as e:
        log("ERROR", str(e))
        sys.exit(1)
