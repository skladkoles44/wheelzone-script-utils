#!/data/data/com.termux/files/usr/bin/python3
#!/data/data/com.termux/files/usr/bin/python3
import json
import os
import sys
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log_json(level, **kwargs):
    print(json.dumps({"time": utc_now(), "level": level, **kwargs}))


def load_env():
    env_path = os.path.expanduser("~/wheelzone-script-utils/configs/.env.notion")
    if not os.path.isfile(env_path):
        raise FileNotFoundError(f"Not found: {env_path}")
    load_dotenv(env_path)


def build_payload(page_id: str) -> dict:
    return {
        "parent": {"type": "page_id", "page_id": page_id},
        "title": [{"type": "text", "text": {"content": "WZ Tasks"}}],
        "properties": {
            "Name": {"title": {}},
            "Status": {
                "select": {
                    "options": [
                        {"name": "TODO", "color": "red"},
                        {"name": "In Progress", "color": "yellow"},
                        {"name": "Done", "color": "green"},
                    ]
                }
            },
            "Priority": {
                "select": {
                    "options": [
                        {"name": "Low", "color": "gray"},
                        {"name": "Medium", "color": "blue"},
                        {"name": "High", "color": "orange"},
                        {"name": "Critical", "color": "red"},
                    ]
                }
            },
            "Tags": {"multi_select": {}},
            "Source": {
                "select": {
                    "options": [
                        {"name": "manual", "color": "default"},
                        {"name": "chatend", "color": "blue"},
                        {"name": "CI", "color": "purple"},
                    ]
                }
            },
            "Created": {"date": {}},
        },
    }


def create_notion_db(token: str, page_id: str):
    url = "https://api.notion.com/v1/databases"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Notion-Version": "2022-06-28",
    }
    data = build_payload(page_id)

    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        r = response.json()
        log_json("INFO", status="success", database_id=r.get("id"), url=r.get("url"))
    except requests.exceptions.HTTPError as e:
        log_json(
            "ERROR",
            status="error",
            type="HTTPError",
            error=str(e),
            response=response.text,
        )
        sys.exit(1)
    except Exception as e:
        log_json("ERROR", status="error", type=type(e).__name__, error=str(e))
        sys.exit(1)


def main():
    try:
        load_env()
        token = os.environ["NOTION_TOKEN"]
        name_arg = sys.argv[1] if len(sys.argv) > 1 else "TASKS"
        env_var = f"PARENT_PAGE_ID_{name_arg.upper()}"
        page_id = os.environ.get(env_var)
        if not page_id:
            raise EnvironmentError(f"❌ Переменная окружения {env_var} не найдена")
        create_notion_db(token, page_id)
    except Exception as e:
        log_json("ERROR", status="error", type=type(e).__name__, error=str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
