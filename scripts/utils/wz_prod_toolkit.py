import os, time, shutil, shlex, subprocess, csv
from tempfile import NamedTemporaryFile
import requests

def http_get(url, timeout=(3.05, 10), retries=2, backoff=0.5, **kwargs):
    for i in range(retries + 1):
        try:
            r = requests.get(url, timeout=timeout, **kwargs)
            r.raise_for_status()
            return r
        except (requests.Timeout, requests.ConnectionError):
            if i == retries:
                raise
            time.sleep(backoff * (2 ** i))

def atomic_copy(src: str, dst: str, bufsize: int = 1024 * 1024):
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    with open(src, "rb") as fin, NamedTemporaryFile("wb", delete=False, dir=os.path.dirname(dst) or ".") as tmp:
        shutil.copyfileobj(fin, tmp, length=bufsize)
        tmp_path = tmp.name
    os.replace(tmp_path, dst)

def run_cmd(cmd: str, check: bool = True):
    return subprocess.run(shlex.split(cmd), check=check)

def run_argv(argv: list[str], check: bool = True):
    return subprocess.run(argv, check=check)

def process_csv(path: str, row_handler):
    with open(path, newline="") as f:
        for row in csv.reader(f):
            row_handler(row)
