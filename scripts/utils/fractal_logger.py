#!/usr/bin/env python3

import argparse
import json
import os
import datetime
import sys

def sanitize(s):
if s is None:
return None
return str(s).strip().replace("\n", " ").replace("\r", "")

def main():
parser = argparse.ArgumentParser(description="Fractal Logger for WheelZone")
parser.add_argument("--title", required=True, help="Event title")
parser.add_argument("--type", required=True, help="Event type (e.g., core, meta, quant)")
parser.add_argument("--details", help="Additional details")
parser.add_argument("--principles", nargs="*", default=[], help="List of triggered core principles")
args = parser.parse_args()

log_entry = {  
    "timestamp": datetime.datetime.utcnow().isoformat(timespec='seconds') + "Z",  
    "title": sanitize(args.title),  
    "type": sanitize(args.type),  
    "details": sanitize(args.details),  
    "principles_triggered": [sanitize(p) for p in args.principles]  
}  

log_path = os.path.expanduser("~/.wz_quantum_log.json")  
try:  
    with open(log_path, "a", encoding="utf-8") as log_file:  
        json.dump(log_entry, log_file, ensure_ascii=False)  
        log_file.write("\n")  
except (IOError, OSError) as e:  
    print(f"[ERROR] Failed to write log: {e}", file=sys.stderr)  
    sys.exit(1)

if name == "main":
main()
