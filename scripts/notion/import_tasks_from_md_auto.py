#!/usr/bin/env python3
import os
import re
import time
import hashlib
import logging
from typing import List, Dict, Set, Tuple, Optional
from notion_client import Client
from dotenv import load_dotenv

REQUIRED_PROPERTIES = {
    "Name": {"title": {}},
    "Description": {"rich_text": {}},
    "Recommendations": {"rich_text": {}},
    "Categories": {"multi_select": {}},
    "Status": {"select": {}},
    "Source": {"rich_text": {}}
}

PROPERTY_TEMPLATE = {
    "Name": lambda t: {"title": [{"text": {"content": t[0]}}]},
    "Description": lambda t: {"rich_text": [{"text": {"content": t[1]}}]},
    "Recommendations": lambda t: {"rich_text": [{"text": {"content": t[2]}}]},
    "Status": lambda _: {"select": {"name": "Open"}},
    "Source": lambda _: {"rich_text": [{"text": {"content": "TODO_notionsync.md"}}]}
}

class NotionTaskImporter:
    def __init__(self):
        self.processed_hashes: Set[str] = set()
        self.success: int = 0
        self.total: int = 0
        self.logger: logging.Logger = logging.getLogger("NotionImporter")
        self._notion: Optional[Client] = None
        self._db_id: Optional[str] = None

    @property
    def notion(self) -> Client:
        if self._notion is None:
            token, _ = self._load_config()
            self._notion = Client(auth=token)
        return self._notion

    @property
    def database_id(self) -> str:
        if not self._db_id:
            _, db_id = self._load_config()
            self._db_id = db_id
        return self._db_id

    def _load_config(self) -> Tuple[str, str]:
        env_path = os.path.expanduser("~/.env.notion")
        if not os.path.exists(env_path):
            raise FileNotFoundError(f"Config file not found: {env_path}")
        load_dotenv(dotenv_path=env_path, override=True)
        try:
            return (
                os.environ["NOTION_TOKEN"],
                os.environ["DATABASE_ID"]
            )
        except KeyError as e:
            raise ValueError(f"Missing env variable: {e}")

    def _parse_categories(self, category_str: Optional[str]) -> List[str]:
        VALID = {"🧪", "📦", "🔧", "🚀"}
        if not category_str:
            return []
        return [c for c in category_str if c in VALID]

    def _build_properties(self, task: Tuple[str, str, str, List[str]]) -> Dict:
        properties = {k: v(task) for k, v in PROPERTY_TEMPLATE.items()}
        if task[3]:  # Категории
            properties["Categories"] = {
                "multi_select": [{"name": c} for c in task[3]]
            }
        return properties

    def _process_markdown(self, content: str) -> List[Tuple[str, str, str, List[str]]]:
        tasks = []
        for match in re.finditer(
            r"(\d+)\.\s(.*?)\n\s*🔸(.*?)\n\s*🔹(.*?)(?:\n\s*([🧪📦🔧🚀\s]+))?(?:\n|$)",
            content,
            re.DOTALL
        ):
            _, title, desc, recommend, categories = match.groups()
            tasks.append((
                title.strip(),
                desc.strip(),
                recommend.strip(),
                self._parse_categories(categories)
            ))
        return tasks

    def check_and_create_schema(self) -> None:
        try:
            current = self.notion.databases.retrieve(self.database_id).get("properties", {})
            missing = [k for k in REQUIRED_PROPERTIES if k not in current]
            if missing:
                update_payload = {
                    "properties": {
                        k: REQUIRED_PROPERTIES[k] for k in missing
                    }
                }
                self.notion.databases.update(self.database_id, **update_payload)
                self.logger.info(f"Created missing fields: {missing}")
        except Exception as e:
            self.logger.error(f"Schema update failed: {e}")
            raise

    def run(self, file_path: str, dry_run: bool = False) -> None:
        logging.basicConfig(
            level=logging.INFO,
            format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s"}',
            handlers=[logging.StreamHandler()]
        )

        try:
            with open(os.path.expanduser(file_path), "r", encoding="utf-8") as f:
                content = f.read()

            self.check_and_create_schema()
            tasks = self._process_markdown(content)

            for task in tasks:
                task_str = "|".join(task[:3])
                task_hash = hashlib.blake2b(task_str.encode(), digest_size=16).hexdigest()
                self.total += 1

                if task_hash in self.processed_hashes:
                    continue

                if dry_run:
                    self.logger.info(f"DRY-RUN: {task[0]}")
                    continue

                try:
                    self.notion.pages.create(
                        parent={"database_id": self.database_id},
                        properties=self._build_properties(task)
                    )
                    self.success += 1
                    self.processed_hashes.add(task_hash)
                    time.sleep(0.5)
                except Exception as e:
                    self.logger.error(f"Failed to create task: {task[0]} - {e}")

            self.logger.info(f"Imported {self.success}/{self.total} tasks")
        except FileNotFoundError:
            self.logger.error(f"File not found: {file_path}")
            raise SystemExit(1)
        except Exception as e:
            self.logger.error(f"Fatal error: {e}", exc_info=True)
            raise SystemExit(1)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Test mode (no changes)")
    parser.add_argument("--file", default="~/wz-wiki/docs/TODO_notionsync.md", help="Markdown file path")
    args = parser.parse_args()

    NotionTaskImporter().run(args.file, args.dry_run)
