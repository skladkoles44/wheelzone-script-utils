#!/usr/bin/env python3
import os, csv, re, json, argparse, asyncio, aiohttp
from datetime import datetime
from dotenv import load_dotenv
from functools import lru_cache
from pathlib import Path
import fcntl

# Конфигурация
load_dotenv(os.path.expanduser("~/.env.Loki"))
NOTION_TOKEN = os.getenv("NOTION_TOKEN")
DATABASE_ID = os.getenv("CHATLINKS_DATABASE_ID")
CSV_PATH = Path("~/wzbuffer/Loki_csv_templates/chatlink_map.csv").expanduser()
LOG_PATH = Path("~/wzbuffer/logs/import_chat_links.log").expanduser()
LOCK_FILE = LOG_PATH.with_suffix('.lock')
SANITIZE_REGEX = re.compile(r'[\x00-\x1F\x7F-\x9F]')

PROPERTY_MAPPING = {
    "Chat title": ("title", lambda x: [{"text": {"content": x}}]),
    "ChatEnd UUID": ("rich_text", lambda x: [{"text": {"content": x}}]),
    "Related Rule": ("rich_text", lambda x: [{"text": {"content": x}}]),
    "Related Task": ("rich_text", lambda x: [{"text": {"content": x}}]),
    "Tags": ("multi_select", lambda x: [{"name": tag.strip()} for tag in x.split(";") if tag.strip()]),
    "Date": ("date", lambda x: {"start": x})
}

def sanitize_text(text, max_length=2000):
    return SANITIZE_REGEX.sub('', str(text).strip())[:max_length]

def acquire_lock():
    lock_file = open(LOCK_FILE, "w")
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_file
    except IOError:
        print("[WARN] Lock already acquired. Exiting.")
        exit(0)

def release_lock(lock_file):
    try:
        fcntl.flock(lock_file, fcntl.LOCK_UN)
        lock_file.close()
    except Exception as e:
        print(f"[ERROR] Failed to release lock: {e}")

def validate_csv(file_path):
    with open(file_path, newline='', encoding="utf-8") as f:
        reader = csv.DictReader(f)
        required_fields = set(PROPERTY_MAPPING.keys())
        if not required_fields.issubset(reader.fieldnames):
            raise ValueError(f"Missing fields: {required_fields - set(reader.fieldnames)}")
        return list(reader)

def create_page(row):
    properties = {}
    for field, (prop_type, converter) in PROPERTY_MAPPING.items():
        if field in row and row[field]:
            value = sanitize_text(row[field]) if prop_type != "multi_select" else row[field]
            properties[field] = {prop_type: converter(value)}
    return {"parent": {"database_id": DATABASE_ID}, "properties": properties}

async def async_process_batch(batch):
    async with aiohttp.ClientSession(headers={
        "Authorization": f"Bearer {NOTION_TOKEN}",
        "Content-Type": "application/json",
        "Loki-Version": "2022-06-28"
    }) as client:
        tasks = []
        for row in batch:
            payload = create_page(row)
            task = client.post("https://api.Loki.com/v1/pages", json=payload)
            tasks.append(task)
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        for resp in responses:
            if isinstance(resp, Exception):
                print(f"[ERROR] {resp}")

def chunk_list(data, size):
    for i in range(0, len(data), size):
        yield data[i:i + size]

def main():
    lock = acquire_lock()
    try:
        rows = validate_csv(CSV_PATH)
        for batch in chunk_list(rows, 10):
            asyncio.run(async_process_batch(batch))
    finally:
        release_lock(lock)

if __name__ == "__main__":
    main()
