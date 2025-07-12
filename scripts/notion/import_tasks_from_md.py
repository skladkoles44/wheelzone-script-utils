#!/usr/bin/env python3
import os
import re
import time
import hashlib
import logging
from dataclasses import dataclass
from typing import List, Dict
from functools import cached_property
from threading import Lock
from tqdm import tqdm
from notion_client import Client
from notion_client.errors import APIResponseError
from dotenv import load_dotenv

class Config:
    MAX_LENGTH = 2000
    REQUEST_DELAY = 0.5
    MAX_RETRIES = 3
    VALID_CATEGORIES = {"🧪", "📦", "🔧", "🚀"}
    LOG_FORMAT = '{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}'
    MARKDOWN_PATTERN = r"(\d+)\.\s(.*?)\n\s*🔸(.*?)\n\s*🔹(.*?)(?:\n\s*([🧪📦🔧🚀\s]+))?(?:\n|$)"
    SOURCE_TEXT = "TODO_notionsync.md"
    DELIMITER = "|"

@dataclass
class Task:
    title: str
    description: str
    recommendations: str
    categories: List[str]

PROPERTY_TEMPLATE = {
    "Name": lambda t: {"title": [{"text": {"content": t.title}}]},
    "Description": lambda t: {"rich_text": [{"text": {"content": t.description}}]},
    "Recommendations": lambda t: {"rich_text": [{"text": {"content": t.recommendations}}]},
    "Status": lambda _: {"select": {"name": "Open"}},
    "Source": lambda _: {"rich_text": [{"text": {"content": Config.SOURCE_TEXT}}]}
}

def validate_length(text: str, field: str) -> str:
    if len(text.strip()) > Config.MAX_LENGTH:
        raise ValueError(f"{field} exceeds max length ({Config.MAX_LENGTH})")
    return text.strip()

class NotionTaskImporter:
    def __init__(self):
        self.processed_hashes = set()
        self._hash_lock = Lock()
        self.success = 0
        self.total = 0
        self.logger = logging.getLogger(__name__)

    @cached_property
    def notion(self) -> Client:
        token, _ = self._load_config()
        return Client(auth=token)

    def _load_config(self) -> tuple:
        env_path = os.path.expanduser("~/.env.notion")
        if not os.path.exists(env_path):
            raise FileNotFoundError(f"❌ Config not found: {env_path}")
        load_dotenv(dotenv_path=env_path, override=True)
        try:
            return (
                os.environ["NOTION_TOKEN"],
                os.environ["DATABASE_ID"]
            )
        except KeyError as e:
            raise ValueError(f"Missing env variable: {e}")

    def _parse_categories(self, raw: str) -> List[str]:
        return [c for c in (raw or "") if c in Config.VALID_CATEGORIES]

    def _build_properties(self, task: Task) -> Dict:
        props = {k: v(task) for k, v in PROPERTY_TEMPLATE.items()}
        if task.categories:
            props["Categories"] = {"multi_select": [{"name": c} for c in task.categories]}
        return props

    def _get_task_hash(self, task: Task) -> str:
        data = f"{task.title}{Config.DELIMITER}{task.description}{Config.DELIMITER}{task.recommendations}"
        return hashlib.blake2b(data.encode(), digest_size=16).hexdigest()

    def _add_processed_hash(self, task_hash: str):
        with self._hash_lock:
            self.processed_hashes.add(task_hash)

    def _parse_tasks(self, text: str) -> List[Task]:
        tasks = []
        for match in re.finditer(Config.MARKDOWN_PATTERN, text, re.DOTALL):
            _, title, desc, rec, cats = match.groups()
            try:
                task = Task(
                    validate_length(title, "Title"),
                    validate_length(desc, "Description"),
                    validate_length(rec, "Recommendations"),
                    self._parse_categories(cats)
                )
                tasks.append(task)
            except ValueError as e:
                self.logger.warning(f"⚠️ Skipped: {e}")
        return tasks

    def run(self, file_path: str, dry_run: bool = False):
        logging.basicConfig(
            level=logging.INFO,
            format=Config.LOG_FORMAT,
            handlers=[logging.StreamHandler()]
        )

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Markdown file not found: {file_path}")

        _, db_id = self._load_config()

        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()

        tasks = self._parse_tasks(content)

        for task in tqdm(tasks, desc="Processing tasks"):
            task_hash = self._get_task_hash(task)
            self.total += 1
            if task_hash in self.processed_hashes:
                continue
            if dry_run:
                self.logger.info(f"DRY-RUN: {task.title}")
                continue
            for attempt in range(Config.MAX_RETRIES):
                try:
                    self.notion.pages.create(
                        parent={"database_id": db_id},
                        properties=self._build_properties(task)
                    )
                    self._add_processed_hash(task_hash)
                    self.success += 1
                    time.sleep(Config.REQUEST_DELAY)
                    break
                except APIResponseError as e:
                    if getattr(e, "code", "") == "rate_limited":
                        retry_after = int(e.headers.get("Retry-After", 5))
                        time.sleep(retry_after)
                    elif attempt == Config.MAX_RETRIES - 1:
                        self.logger.error(f"❌ Failed task: {task.title}", exc_info=True)
                    else:
                        time.sleep((attempt + 1) * 2)

        self.logger.info(f"🎯 Imported {self.success}/{self.total} tasks successfully.")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Не отправлять в Notion")
    parser.add_argument("--file", default="~/wz-wiki/docs/TODO_notionsync.md", help="Путь до markdown-файла")
    args = parser.parse_args()

    importer = NotionTaskImporter()
    importer.run(os.path.expanduser(args.file), args.dry_run)
