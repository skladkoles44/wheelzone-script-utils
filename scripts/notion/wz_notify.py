#!/usr/bin/env python3
# wz_notify.py v3.5.0 — PlatinumNotifier (WBP, Termux-compatible)

import os
import json
import logging
import argparse
import datetime
import requests
import uuid
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PlatinumNotifier:
    def __init__(self, zero_trust=False):
        self.zero_trust = zero_trust
        self.script_dir = self._secure_path_resolution()
        self.env_file = self._validate_env_path()
        self.env = self._load_env_vars()
        self.session_id = self._generate_entropy_id()
        self.notion_token = self.env.get("NOTION_TOKEN")
        self.database_id = self.env.get("NOTION_LOG_DB_ID")
        self.headers = self._generate_headers()

    def _secure_path_resolution(self):
        try:
            return Path(__file__).resolve().parent
        except Exception as e:
            logger.warning(f"[WARN] Fallback to . for script path: {e}")
            return Path(".").resolve()

    def _validate_env_path(self):
        env_path = Path(os.path.expanduser("~/.env.wzbot"))
        if not env_path.exists():
            raise FileNotFoundError(f"Env file missing: {env_path}")
        return env_path

    def _load_env_vars(self):
        env_vars = {}
        with open(self.env_file, "r") as f:
            for line in f:
                if "=" in line and not line.strip().startswith("#"):
                    key, val = line.strip().split("=", 1)
                    env_vars[key.strip()] = val.strip().strip('"\'')
        required = ["NOTION_TOKEN", "NOTION_LOG_DB_ID"]
        for key in required:
            if key not in env_vars:
                raise KeyError(f"Required env key missing: {key}")
        return env_vars

    def _generate_entropy_id(self):
        return uuid.uuid4().hex

    def _generate_headers(self):
        return {
            "Authorization": f"Bearer {self.notion_token}",
            "Notion-Version": "2022-06-28",
            "Content-Type": "application/json",
        }

    def _build_payload(self, title, status, tag, desc):
        now = datetime.datetime.now(datetime.timezone.utc).isoformat()
        return {
            "parent": {"database_id": self.database_id},
            "properties": {
                "Name": {"title": [{"text": {"content": title}}]},
                "Status": {"select": {"name": status}},
                "Tags": {"multi_select": [{"name": tag}]},
                "Session": {"rich_text": [{"text": {"content": self.session_id}}]},
                "Timestamp": {"date": {"start": now}},
            },
            "children": [
                {"object": "block", "type": "paragraph", "paragraph": {
                    "rich_text": [{"text": {"content": desc}}]
                }}
            ]
        }

    def _send_to_notion(self, payload):
        url = "https://api.notion.com/v1/pages"
        response = requests.post(url, headers=self.headers, data=json.dumps(payload), timeout=15)
        self._handle_response(response)

    def _handle_response(self, response):
        if response.status_code != 200:
            logger.error(f"[!] Notion API error {response.status_code}: {response.text}")
            raise RuntimeError("Notion request failed")
        logger.info("✅ Notion log created successfully")

    def notify(self, title, status, tag, desc=""):
        payload = self._build_payload(title, status, tag, desc)
        self._send_to_notion(payload)

    def run_selftest(self):
        logger.info("=== Self-Test ===")
        self.notify(
            title="Self-Test wz_notify.py",
            status="SELFTEST",
            tag="test",
            desc="🧪 Self-test passed successfully"
        )

def main():
    parser = argparse.ArgumentParser(description="WZ Notifier CLI")
    parser.add_argument("--type", required=True, help="Тип события (test, system, error и т.п.)")
    parser.add_argument("--title", required=True, help="Заголовок события")
    parser.add_argument("--desc", default="", help="Описание события")
    parser.add_argument("--tag", default="infra", help="Тег события (по умолчанию: infra)")
    parser.add_argument("--status", default="PUSHED", help="Статус события (по умолчанию: PUSHED)")
    parser.add_argument("--source", default="Termux", help="Источник (для расширения)")
    parser.add_argument("--selftest", action="store_true", help="Запустить самопроверку")

    args = parser.parse_args()
    notifier = PlatinumNotifier()

    if args.selftest:
        notifier.run_selftest()
    else:
        notifier.notify(
            title=args.title,
            status=args.status,
            tag=args.tag,
            desc=args.desc
        )

if __name__ == "__main__":
    main()
