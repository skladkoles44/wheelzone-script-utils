#!/usr/bin/env python3
# wz_notify_log_uuid.py v2.1 — Optimized UUID Loki Logger (CI/Termux Ready)

import os
import sys
import json
import uuid
import argparse
from datetime import datetime, timezone, timezone, timezone
from pathlib import Path
from filelock import FileLock  # pip install filelock

DEFAULT_ENV = str(Path.home() / ".env.wzbot")
OFFLINE_LOG = str(Path.home() / ".wz_offline_log.jsonl")

def load_env(path=DEFAULT_ENV):
    env = {}
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip()
    return env

def build_payload(args, session_id, timestamp):
    return {
        "uuid": args.uuid or f"uuid-{timestamp[:10].replace('-', '')}-{session_id}",
        "session_id": session_id,
        "type": args.type,
        "node": args.node,
        "source": args.source,
        "timestamp": args.timestamp or timestamp,
        "title": args.title,
        "message": args.message
    }

def save_offline(payload):
    Path(OFFLINE_LOG).parent.mkdir(parents=True, exist_ok=True)
    lock = FileLock(OFFLINE_LOG + ".lock")
    with lock:
        with open(OFFLINE_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(payload, ensure_ascii=False) + "\n")

def validate_args(args):
    for field in ["type", "node", "source", "title", "message"]:
        if not getattr(args, field):
            raise ValueError(f"Поле {field} не может быть пустым!")

def main():
    parser = argparse.ArgumentParser(description="Логгер UUID событий в Loki/Termux/CI")
    parser.add_argument("--uuid", help="UUID события (если не указано, генерируется)")
    parser.add_argument("--session_id", help="ID сессии (если не указано, берётся из UUID или генерируется)")
    parser.add_argument("--type", required=True, help="Тип события (core, ci, system, etc.)")
    parser.add_argument("--node", required=True, help="Имя узла или устройства")
    parser.add_argument("--source", required=True, help="Источник (скрипт, файл, компонент)")
    parser.add_argument("--timestamp", help="Время события ISO8601 (если не указано, используется текущее)")
    parser.add_argument("--title", required=True, help="Заголовок события")
    parser.add_argument("--message", required=True, help="Основное сообщение события")
    parser.add_argument("--test", action="store_true", help="Тестовый режим (stdout без отправки)")

    args = parser.parse_args()
    validate_args(args)

    current_time = datetime.now(timezone.utc).isoformat()
    session_id = args.session_id or (
        args.uuid.split("-")[-1] if args.uuid and "-" in args.uuid
        else uuid.uuid4().hex[:6]
    )

    payload = build_payload(args, session_id, current_time)

    if args.test:
        print("[TEST MODE] Payload:")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return

    try:
        env = load_env()
        save_offline(payload)
        print(f"[OK] Событие сохранено: {OFFLINE_LOG}")
    except Exception as e:
        print(f"[ERROR] Ошибка: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
