#!/data/data/com.termux/files/usr/bin/python3
"""
Notion Logger CLI v2.3 — Финальная проверенная версия
"""

import argparse
import os
import sys
from datetime import datetime, timezone
from typing import Any, Dict, NoReturn, Tuple

import requests

_ENV_CACHE: Dict[str, str] = None  # Кэш env-переменных


def log_error(message: str, exit_code: int = 1) -> NoReturn:
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(exit_code)


def iso_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def load_env() -> Tuple[str, str]:
    global _ENV_CACHE
    if _ENV_CACHE is None:
        try:
            _ENV_CACHE = _load_env_from_file()
        except Exception as e:
            log_error(f"Environment loading failed: {str(e)}")

    token = _ENV_CACHE.get("NOTION_API_TOKEN")
    db_id = _ENV_CACHE.get("NOTION_LOG_DB_ID")

    if not token:
        log_error("NOTION_API_TOKEN not set in environment")
    if not db_id:
        log_error("NOTION_LOG_DB_ID not set in environment")
    return token, db_id


def _load_env_from_file() -> Dict[str, str]:
    path = os.path.expanduser("~/.env.wzbot")
    env_vars = {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line_number, line in enumerate(f, 1):
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" not in line:
                    continue
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip("'\"")
                if not key:
                    continue
                env_vars[key] = value
    except FileNotFoundError:
        log_error(f"Env file not found: {path}")
    except PermissionError:
        log_error(f"No permission to read file: {path}")
    except UnicodeDecodeError:
        log_error(f"Invalid encoding in file: {path}")
    except Exception as e:
        log_error(f"Unexpected error reading {path}: {str(e)}")
    return env_vars


def build_payload(args: argparse.Namespace) -> Dict[str, Any]:
    try:
        return {
            "parent": {"database_id": args.db_id},
            "properties": {
                "Name": {"title": [{"text": {"content": str(args.name)[:2000]}}]},
                "Type": {
                    "select": {"name": _validate_select_value(str(args.type)[:100])}
                },
                "Event": {"rich_text": [{"text": {"content": str(args.event)[:2000]}}]},
                "Result": {
                    "rich_text": [{"text": {"content": str(args.result)[:2000]}}]
                },
                "Source": {
                    "rich_text": [{"text": {"content": str(args.source)[:2000]}}]
                },
                "Timestamp": {"date": {"start": iso_now()}},
            },
        }
    except Exception as e:
        log_error(f"Payload construction failed: {str(e)}")


def _validate_select_value(value: str) -> str:
    if not value or len(value) > 100:
        log_error(f"Invalid select value: {value}")
    return value


def send_to_notion(token: str, payload: Dict[str, Any]) -> None:
    url = "https://api.notion.com/v1/pages"
    headers = {
        "Authorization": f"Bearer {token}",
        "Notion-Version": "2022-06-28",
        "Content-Type": "application/json",
    }
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=(3.05, 10))
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        error_msg = f"Notion API error: {str(e)}"
        if e.response is not None:
            try:
                error_details = e.response.json()
                error_msg += f"\nDetails: {error_details}"
            except ValueError:
                error_msg += f"\nResponse: {e.response.text[:500]}"
        log_error(error_msg)
    except requests.exceptions.RequestException as e:
        log_error(f"Network error: {str(e)}")
    except Exception as e:
        log_error(f"Unexpected API error: {str(e)}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Log event to Notion database",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--type", required=True, help="Entry type (e.g. 'system', 'alert')"
    )
    parser.add_argument("--name", required=True, help="Short name/identifier")
    parser.add_argument("--event", required=True, help="Event description")
    parser.add_argument("--result", default="ok", help="Result status")
    parser.add_argument("--source", required=True, help="Source of the event")

    try:
        args = parser.parse_args()
        token, db_id = load_env()
        args.db_id = db_id
        payload = build_payload(args)
        send_to_notion(token, payload)
    except KeyboardInterrupt:
        log_error("Operation cancelled by user", exit_code=130)
    except Exception as e:
        log_error(f"Unexpected error: {str(e)}")


if __name__ == "__main__":
    main()
