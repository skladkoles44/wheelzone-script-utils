#!/usr/bin/env python3
# WheelZone :: Safe Autofixer — minimal-risk edits only (fast edition)
# fractal_uuid: "7b5b5f0d-0e1b-4a07-9c3e-7c7d7f0f1b2a"
# Version: 1.0.2
# Author: Себастьян Перейра
# Purpose: Автоматически чинить безопасные антипаттерны без тяжёлых regex: timeout/verify/safe_load,
#          curl -k/--insecure, wget --no-check-certificate, SSH StrictHostKeyChecking=no -> accept-new.
# Logs: /storage/emulated/0/Download/project_44/Logs

import os, sys, re, json, argparse, pathlib
from datetime import datetime, UTC

LOG_DIR = os.path.expanduser('/storage/emulated/0/Download/project_44/Logs')
os.makedirs(LOG_DIR, exist_ok=True)

TEXT_EXTS = {".py",".sh",".bash",".zsh",".service",".timer",".conf",".cfg",".ini",".env",".yml",".yaml",".txt"}
EXCLUDE_RE = re.compile(r"/(\.git|\.hg|\.svn|\.venv|venv|node_modules|__pycache__|site-packages|dist-packages|build|dist|\.backup)/")

# ---------- helpers ----------
def is_text_file(p: pathlib.Path) -> bool:
    if p.suffix.lower() in TEXT_EXTS:
        return True
    try:
        with open(p, 'rb') as f:
            head = f.read(1024)
        return b'\x00' not in head
    except Exception:
        return False

def backup_path(root: pathlib.Path, p: pathlib.Path, ts: str) -> pathlib.Path:
    rel = p.relative_to(root)
    bdir = root / f'.backup/{ts}'
    bpath = bdir / rel
    bpath.parent.mkdir(parents=True, exist_ok=True)
    return bpath

def write_text_atomic(path: pathlib.Path, data: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.parent / (".tmp." + path.name)
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)

# ---------- Python transformers (без тяжёлых regex) ----------
REQ_FUNCS = ("get","post","put","delete","head","patch")

def _scan_requests_calls(src: str):
    """
    Находит вызовы вида requests.<func>( ... ) с балансировкой скобок.
    Возвращает список кортежей: (start_index, end_index) границы скобок от '(' до соответствующей ')'.
    """
    out = []
    i, n = 0, len(src)
    while i < n:
        j = src.find("requests.", i)
        if j == -1: break
        k = j + len("requests.")
        # имя функции
        ok = False
        for fn in REQ_FUNCS:
            if src.startswith(fn, k):
                k2 = k + len(fn)
                # пропускаем пробелы
                while k2 < n and src[k2].isspace(): k2 += 1
                if k2 < n and src[k2] == '(':
                    # парсим скобки
                    start = k2
                    depth = 0
                    q = None  # кавычки
                    esc = False
                    x = start
                    while x < n:
                        ch = src[x]
                        if q:
                            if esc:
                                esc = False
                            elif ch == '\\':
                                esc = True
                            elif ch == q:
                                q = None
                        else:
                            if ch in ('"', "'"):
                                q = ch
                            elif ch == '(':
                                depth += 1
                            elif ch == ')':
                                depth -= 1
                                if depth == 0:
                                    out.append((start, x))  # включительно границы скобок
                                    i = x + 1
                                    ok = True
                                    break
                        x += 1
                if ok:
                    break
        if not ok:
            i = k
    return out

def _args_has_kw(argstr: str, kw: str) -> bool:
    # грубая проверка наличия kw= вне строк; достаточно для безопасной правки
    s = argstr
    n = len(s)
    i = 0
    q = None
    esc = False
    while i < n:
        ch = s[i]
        if q:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == q:
                q = None
        else:
            if ch in ('"', "'"):
                q = ch
            else:
                # match kw=
                if s.startswith(kw, i):
                    j = i + len(kw)
                    while j < n and s[j].isspace(): j += 1
                    if j < n and s[j] == '=':
                        return True
        i += 1
    return False

def _append_kw(argstr: str, insert: str) -> str:
    # вставляем перед закрывающей скобкой: учитываем хвостовые пробелы
    rs = argstr.rstrip()
    tail = argstr[len(rs):]
    if rs.endswith('('):
        return rs + insert + ')' + tail
    if rs.endswith(','):
        return rs + ' ' + insert + ')' + tail
    return rs + ', ' + insert + ')' + tail

def fix_requests(src: str):
    """
    Добавляет timeout=(2,10), если нет. Заменяет verify=False -> verify=True.
    Возвращает (new_src, changed: bool)
    """
    spans = _scan_requests_calls(src)
    if not spans:
        return src, False
    new = []
    last = 0
    changed = False
    for (l, r) in spans:
        # сегмент до вызова
        new.append(src[last:l+1])  # до и включая '('
        argstr = src[l+1:r]        # внутри скобок
        orig = argstr

        # verify=False -> verify=True (внутри аргументов без парсинга AST)
        argstr = re.sub(r'(\bverify\s*=\s*)False\b', r'***REMOVED***True', argstr)

        # timeout — если отсутствует
        if not _args_has_kw(argstr, "timeout"):
            argstr = (argstr + ', timeout=(2,10)') if argstr.strip() else 'timeout=(2,10)'

        if argstr != orig:
            changed = True

        new.append(argstr)
        new.append(src[r])         # ')'
        last = r+1

    new.append(src[last:])
    return ''.join(new), changed

def fix_yaml_safe_load(src: str):
    # простая замена yaml.safe_load(...) -> yaml.safe_load(...) если нет Loader=
    def repl(m):
        inside = m.group(1)
        if 'Loader=' in inside:
            return m.group(0)
        return f'yaml.safe_load({inside})'
    out = re.sub(r'\byaml\.load\s*\(([^)]*?)\)', repl, src)
    return out, (out != src)

def fix_urllib3_disable_warnings(src: str):
    out = re.sub(r'^\s*urllib3\.disable_warnings\([^\n]*\)\s*$', lambda m: '# ' + m.group(0), src, flags=re.MULTILINE)
    return out, (out != src)

# ---------- Shell transformers (построчно) ----------
def fix_curl_line(line: str) -> tuple[str,bool]:
    if "curl" not in line:
        return line, False
    o = line
    line = re.sub(r'\s--insecure(\s|$)', ' ', line)
    line = re.sub(r'\s-k(\s|$)', ' ', line)
    return line, (line != o)

def fix_wget_line(line: str) -> tuple[str,bool]:
    if "wget" not in line:
        return line, False
    o = line
    line = re.sub(r'\s--no-check-certificate(\s|$)', ' ', line)
    return line, (line != o)

def fix_ssh_line(line: str) -> tuple[str,bool]:
    o = line
    line = re.sub(r'StrictHostKeyChecking\s*=\s*no', 'StrictHostKeyChecking=accept-new', line)
    return line, (line != o)

def fix_shell(src: str):
    changed = False
    out_lines = []
    for ln in src.splitlines(keepends=False):
        ln2, c1 = fix_curl_line(ln)
        ln2, c2 = fix_wget_line(ln2)
        ln2, c3 = fix_ssh_line(ln2)
        changed = changed or c1 or c2 or c3
        out_lines.append(ln2)
    if changed:
        return '\n'.join(out_lines) + ('\n' if src.endswith('\n') else ''), True
    return src, False

# ---------- risk-only detection (не правим, только сообщаем) ----------
RISKY_DETECTIONS = [
    ('sql_fstring', re.compile(r'execute\(\s*f["\']')),
    ('sql_concat',  re.compile(r'execute\(\s*["\'][^"\']*["\']\s*\+')),
    ('shell_true',  re.compile(r'subprocess\.(run|Popen|call|check_output)\([^)]*shell\s*=\s*True')),
    ('async_db',    re.compile(r'async\s+def\s+.+\n(?:.|\n){0,400}\bcursor\(')),
    ('open_write',  re.compile(r'open\([^)]*["\'],\s*["\']w["\']')),
    ('logger_fstr', re.compile(r'logger\.(debug|info|warning|error|critical)\(\s*f["\']')),
]

def detect_risky(txt: str):
    hits = []
    for name, rx in RISKY_DETECTIONS:
        if rx.search(txt):
            hits.append(name)
    return sorted(set(hits))

# ---------- main ----------
def main():
    ap = argparse.ArgumentParser(description="Safe Autofixer: быстрые безопасные правки без тяжёлых regex")
    ap.add_argument("paths", nargs="*", default=[os.path.expanduser("~/wheelzone-script-utils"), "/opt/wz-api"])
    ap.add_argument("--apply", action="store_true", help="применить правки (по умолчанию только отчёт)")
    ap.add_argument("--log", default=os.path.join(LOG_DIR, f"wz_autofix_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.jsonl"))
    args = ap.parse_args()

    roots = [pathlib.Path(p) for p in args.paths if pathlib.Path(p).exists()]
    if not roots:
        print(json.dumps({"lvl":"ERROR","msg":"no roots"})); sys.exit(2)

    ts = datetime.now(UTC).strftime('%Y%m%d_%H%M%S')
    total, fixed, risky_cnt = 0, 0, 0

    with open(args.log, "w", encoding="utf-8") as logf:
        for root in roots:
            for p in root.rglob("*"):
                sp = str(p)
                if not p.is_file() or EXCLUDE_RE.search(sp) or not is_text_file(p):
                    continue
                total += 1
                try:
                    src = p.read_text(encoding="utf-8", errors="replace")
                except Exception as e:
                    logf.write(json.dumps({"lvl":"ERROR","path":sp,"err":repr(e)})+"\n")
                    continue

                new = src
                changes = []

                if p.suffix.lower() == ".py":
                    new2, c = fix_requests(new)
                    if c: changes.append("requests_fix"); new = new2
                    new2, c = fix_yaml_safe_load(new)
                    if c: changes.append("yaml_safe_load"); new = new2
                    new2, c = fix_urllib3_disable_warnings(new)
                    if c: changes.append("urllib3_disable_warnings"); new = new2
                else:
                    new2, c = fix_shell(new)
                    if c: changes.append("shell_insecure_flags"); new = new2

                risky = detect_risky(src)
                if risky: risky_cnt += 1

                if changes or risky:
                    entry = {"lvl":"INFO","path":sp,"changes":changes,"risky":risky}
                    logf.write(json.dumps(entry, ensure_ascii=False) + "\n")

                if changes and args.apply:
                    bpath = backup_path(root, p, ts)
                    if not bpath.exists():
                        bpath.parent.mkdir(parents=True, exist_ok=True)
                        bpath.write_text(src, encoding="utf-8")
                    write_text_atomic(p, new)
                    fixed += 1

    summary = {"lvl":"INFO","summary":{"files":total,"fixed":fixed,"risky_detected":risky_cnt,"log":args.log}}
    print(json.dumps(summary, ensure_ascii=False))
    # exit policy: если есть только risky — код 1; если применяли правки — 0; если ничего не нашли — 0
    sys.exit(0 if (fixed>0 or not risky_cnt) else 1)

if __name__ == "__main__":
    main()
