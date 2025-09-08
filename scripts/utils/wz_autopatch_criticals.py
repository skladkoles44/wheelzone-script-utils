#!/usr/bin/env python3
# WheelZone :: Autopatch Criticals (from sweep report)
# fractal_uuid: "6f5a3d8a-9c5e-4a7d-8c8e-8d1a5b7f2c31"
# Version: 1.0.0
# Purpose: По отчёту wz_final_sweep_*.txt исправляет:
#   - subprocess.*( ..., shell=True, ... )  -> shell=False + argv/shlex.split
#   - psycopg2 execute c f-строкой/конкатенациями -> параметризация
# Безопасность: консервативные правки, сложные случаи -> hint-патч и пропуск.
import os, re, sys, json, pathlib, shutil, shlex
from datetime import datetime, timezone

SHELL_METAS = set("|&;><*?$`~")

def now_ts():
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

def read_report(path):
    lines = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for ln in f:
            lines.append(ln.rstrip("\n"))
    return lines

def extract_targets(lines):
    # ожидаем строки вида: /path/file.py:LINE: ...pattern...
    out = {}
    rex = re.compile(r"^(/[^:\n]+\.py):(\d+):")
    for ln in lines:
        m = rex.match(ln)
        if not m: continue
        f = m.group(1); line = int(m.group(2))
        out.setdefault(f, set()).add(line)
    return {k: sorted(v) for k,v in out.items()}

def atomic_write(path: pathlib.Path, data: str):
    tmp = path.with_name(".tmp."+path.name)
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(data); f.flush(); os.fsync(f.fileno())
    os.replace(tmp, path)

def backup(path: pathlib.Path, ts: str):
    bak = path.with_name(f".bak.autopatch.{ts}.{path.name}")
    if not bak.exists():
        shutil.copy2(path, bak)
    return str(bak)

def ensure_import_shlex(src: str) -> str:
    if "shlex.split(" not in src: return src
    if re.search(r'(^|\n)\s*import\s+shlex(\s|$)', src): return src
    # вставим рядом с import subprocess, если есть
    if re.search(r'(^|\n)\s*import\s+subprocess\b', src):
        return re.sub(r'(^|\n)(\s*import\s+subprocess[^\n]*\n)',
                      lambda m: m.group(1)+m.group(2)+"import shlex\n", src, count=1)
    return "import shlex\n" + src

def has_meta(s: str) -> bool:
    return any(ch in s for ch in SHELL_METAS)

def fix_shell_calls(text: str) -> tuple[str, list[str]]:
    hints = []
    # generic cmd var
    def repl_cmd(m):
        args = m.group(1) or ""
        # сохранить check=...
        mcheck = re.search(r'check\s*=\s*(True|False)', args)
        check_part = f", check={mcheck.group(1)}" if mcheck else ""
        return f"subprocess.run(shlex.split(cmd){check_part})"
    text2 = re.sub(
        r'subprocess\.(run|Popen|call|check_output)\(\s*cmd\s*,\s*shell\s*=\s*True\s*(,([^)]*))?\)',
        repl_cmd, text)

    # string literal command
    def repl_str(m):
        func = m.group(1)
        qcmd = m.group(2)  # with quotes
        cmd = shlex.split(qcmd[1:-1]) if not has_meta(qcmd[1:-1]) else None
        args = m.group(3) or ""
        mcheck = re.search(r'check\s*=\s*(True|False)', args)
        check_part = f", check={mcheck.group(1)}" if mcheck else ""
        if cmd is None:
            hints.append("shell_quote_needed")
            return m.group(0)  # сложный шелл — не трогаем
        argv = "[" + ",".join([repr(x) for x in cmd]) + "]"
        return f"subprocess.{func}({argv}{check_part})"
    text2 = re.sub(
        r'subprocess\.(run|Popen|call|check_output)\(\s*(["\'][^"\']+["\'])\s*,\s*shell\s*=\s*True\s*(,([^)]*))?\)',
        repl_str, text2)

    # точечный pgrep f-строка по нашему кейсу
    text2 = re.sub(
        r'subprocess\.run\(\s*f"pgrep -f \'ssh -fN -L \{(\w+)\}\'"\s*,\s*shell\s*=\s*True\s*(,\s*check\s*=\s*(True|False))?\s*\)',
        lambda m: f'subprocess.run(["pgrep","-f", f"ssh -fN -L {{{m.group(1)}}}"]{m.group(2) or ""})', text2)

    # убрать возможные двойные запятые
    def clean_calls(txt: str) -> str:
        def repl(m):
            inner = m.group(1)
            inner = re.sub(r',\s*,', ', ', inner)
            inner = re.sub(r',\s*\)', ')', inner)
            return f"subprocess.run({inner})"
        return re.sub(r'subprocess\.run\((.*?)\)', repl, txt, flags=re.S)
    text2 = clean_calls(text2)

    if text2 != text:
        text2 = ensure_import_shlex(text2)
    return text2, hints

def fix_sql_execute(text: str) -> tuple[str, list[str]]:
    hints = []
    # не трогаем sqlite PRAGMA
    if re.search(r'PRAGMA\s+index_list', text, re.I):
        return text, hints

    # f-string execute(...)
    def repl_f(m):
        fstr = m.group(2)  # содержимое f" ... "
        # Заменим все подстановки {..} на %s, аргументы — просто выбросим (консервативно оставим один var, если простой)
        # Простое извлечение выражений вида {name} / {obj.attr} / {arr[idx]}
        exprs = re.findall(r'\{([^{}]+)\}', fstr)
        params = []
        ok = True
        for e in exprs:
            e = e.strip()
            if re.match(r'^[A-Za-z_][A-Za-z0-9_\.]*(\[[^\]]+\])?$', e):
                params.append(e)
            else:
                ok = False; break
        if not ok or not exprs:
            hints.append("sql_manual_needed")
            return m.group(0)
        sql = re.sub(r'\{[^{}]+\}', r'%s', fstr)
        params_tuple = "(" + ", ".join(params) + ("," if len(params)==1 else "") + ")"
        return f'execute("{sql}", {params_tuple})'
    text2 = re.sub(r'\bexecute\(\s*f("([^"\\]|\\.)*"|\'([^\'\\]|\\.)*\')\s*\)', lambda m: m.group(0).replace("execute(", "execute(") if 0 else repl_f(m), text)

    # конкатенации: "...." + var + "..." -> %s
    def repl_concat(m):
        left = m.group(1); var = m.group(2); right = m.group(3)
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_\.]*(\[[^\]]+\])?$', var):
            hints.append("sql_manual_needed"); return m.group(0)
        sql = left + "%s" + right
        return f'execute("{sql}", ({var},))'
    text2 = re.sub(r'execute\(\s*"([^"]*)"\s*\+\s*([A-Za-z_][A-Za-z0-9_\.]*(\[[^\]]+\])?)\s*\+\s*"([^"]*)"\s*\)', repl_concat, text2)

    return text2, hints

def patch_file(path: str, only_lines: list[int], logf):
    p = pathlib.Path(path)
    try:
        src = p.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        logf.write(json.dumps({"lvl":"ERROR","path":path,"err":repr(e)})+"\n"); return False

    orig = src
    changed = False
    hints = []

    s2, h = fix_shell_calls(src)
    src = s2; hints += h
    s2, h = fix_sql_execute(src)
    src = s2; hints += h

    if src != orig:
        ts = now_ts()
        bak = backup(p, ts)
        atomic_write(p, src)
        logf.write(json.dumps({"lvl":"INFO","path":path,"fixed":["shell_true","sql_param"],"backup":bak,"hints":hints}, ensure_ascii=False)+"\n")
        return True
    else:
        logf.write(json.dumps({"lvl":"INFO","path":path,"fixed":[],"hints":hints}, ensure_ascii=False)+"\n")
        return False

def main():
    if len(sys.argv) < 2:
        print("usage: wz_autopatch_criticals.py /path/to/wz_final_sweep_*.txt [more...]", file=sys.stderr)
        sys.exit(2)
    report_paths = sys.argv[1:]
    targets = {}
    for rp in report_paths:
        for k,v in extract_targets(read_report(rp)).items():
            targets.setdefault(k,set()).update(v)
    if not targets:
        print(json.dumps({"lvl":"ERROR","msg":"no targets in report"})); sys.exit(1)
    log_dir = os.path.expanduser("/storage/emulated/0/Download/project_44/Logs")
    os.makedirs(log_dir, exist_ok=True)
    out = os.path.join(log_dir, f"wz_autopatch_criticals_{now_ts()}.jsonl")
    total=fixed=0
    with open(out, "w", encoding="utf-8") as logf:
        for fpath in sorted(targets.keys()):
            total += 1
            try:
                if patch_file(fpath, sorted(targets[fpath]), logf):
                    fixed += 1
            except Exception as e:
                logf.write(json.dumps({"lvl":"ERROR","path":fpath,"err":repr(e)})+"\n")
    print(json.dumps({"lvl":"INFO","summary":{"files":total,"fixed":fixed,"log":out}}, ensure_ascii=False))

if __name__ == "__main__":
    main()
