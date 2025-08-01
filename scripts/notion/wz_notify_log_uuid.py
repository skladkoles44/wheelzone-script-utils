#!/usr/bin/env python3
# WZ Noiton Logger for UUID events

import argparse, os, json
from datetime import datetime

parser = argparse.ArgumentParser()
parser.add_argument("--uuid", required=True)
parser.add_argument("--type", required=True)
parser.add_argument("--node", required=True)
parser.add_argument("--source", required=True)
parser.add_argument("--timestamp", required=True)
parser.add_argument("--title", required=True)
parser.add_argument("--message", required=True)
args = parser.parse_args()

log_path = os.path.expanduser("~/.wz_logs/uuid_log.ndjson")
os.makedirs(os.path.dirname(log_path), exist_ok=True)

entry = {
    "uuid": args.uuid,
    "type": args.type,
    "node": args.node,
    "source": args.source,
    "timestamp": args.timestamp,
    "title": args.title,
    "message": args.message,
}
with open(log_path, "a", encoding="utf-8") as f:
    f.write(json.dumps(entry, ensure_ascii=False) + "\n")
