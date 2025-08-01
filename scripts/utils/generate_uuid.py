#!/usr/bin/env python3
# generate_uuid.py v4.1.2 — Quantum UUID Generator (Optimized)

import uuid
from datetime import datetime, timezone
import json
import argparse

def get_current_timestamp():
    """Возвращает текущее время в UTC в формате YYYYMMDDHHMMSS."""
    return datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")

def generate_quantum_uuid(raw_uuid: str = None):
    """Генерирует UUID в формате uuid-YYYYMMDDHHMMSS-xxxxxx."""
    raw = raw_uuid or str(uuid.uuid4())
    return f"uuid-{get_current_timestamp()}-{raw[:6]}"

def main():
    parser = argparse.ArgumentParser(
        description="Генератор UUID с поддержкой разных форматов."
    )
    group = parser.add_mutually_exclusive_group()
    
    group.add_argument("--slug", action="store_true", help="Только первые 8 символов UUID")
    group.add_argument("--time", action="store_true", help="Дата в формате YYYYMMDD + короткий UUID")
    group.add_argument("--quantum", action="store_true", help="Формат uuid-YYYYMMDDHHMMSS-xxxxxx")
    group.add_argument("--both", action="store_true", help="Вернуть UUID и SESSION_ID в JSON")
    group.add_argument("--default", action="store_true", help="Стандартный UUID4 (по умолчанию)")

    args = parser.parse_args()
    raw_uuid = str(uuid.uuid4())

    if args.both:
        quantum = generate_quantum_uuid(raw_uuid)
        session_id = quantum.split("-")[-1]
        print(json.dumps({"uuid": quantum, "session_id": session_id}))
    elif args.slug:
        print(raw_uuid[:8])
    elif args.time:
        print(f"{get_current_timestamp()[:8]}-{raw_uuid[:6]}")
    elif args.quantum:
        print(generate_quantum_uuid(raw_uuid))
    else:
        print(raw_uuid)

if __name__ == "__main__":
    main()
