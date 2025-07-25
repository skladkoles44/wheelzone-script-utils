#!/usr/bin/env python3
# WZ Notifier v3.0 -- Zero-Overhead Event Pipeline
import os
import json
import sys
from datetime import datetime as dt
from typing import Dict, NoReturn

__version__ = "3.0.0"
LOG_PATH = f"{os.getenv('HOME', '/tmp')}/.wz_logs/events.ndjson"
MAX_EVENTS = 10_000  # Rotate after N events

class AtomicLogger:
    __slots__ = ('_count',)
    
    def __init__(self):
        self._count = 0
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        
    def _atomic_write(self, data: Dict) -> None:
        try:
            with open(LOG_PATH, 'a', buffering=1) as f:
                f.write(json.dumps(data, separators=(',', ':')) + '\n')
                self._count += 1
        except (IOError, OSError) as e:
            print(f"!LOGERR {e}", file=sys.stderr)
    
    def _rotate_check(self) -> None:
        if self._count >= MAX_EVENTS:
            os.rename(LOG_PATH, f"{LOG_PATH}.{dt.utcnow().timestamp()}")
            self._count = 0

def notify(args: Dict[str, str]) -> NoReturn:
    event = {
        'ts': dt.utcnow().isoformat() + 'Z',
        't': args.get('title', ''),
        'd': args.get('desc', ''),
        'st': args.get('status', 'INFO'),
        'src': args.get('source', sys.argv[0]),
        'v': __version__
    }
    
    logger = AtomicLogger()
    logger._atomic_write(event)
    logger._rotate_check()
    
    if not args.get('quiet'):
        print(f"|{event['st']}| {event['t']}"[:120])
    
    sys.exit(0 if event['st'] == 'INFO' else 1)

def cli_entry() -> None:
    from argparse import ArgumentParser
    p = ArgumentParser()
    p.add_argument('--title', required=True)
    p.add_argument('--desc', default='')
    p.add_argument('--status', default='INFO')
    p.add_argument('--source', default=sys.argv[0])
    p.add_argument('--quiet', action='store_true')
    notify(vars(p.parse_args()))

if __name__ == '__main__':
    cli_entry()
