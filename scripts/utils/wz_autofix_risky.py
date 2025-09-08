#!/usr/bin/env python3
# WheelZone :: Risky Autofixer — conservative AST patches
# fractal_uuid: "0a3a6c24-2c5c-4b0b-9a12-bd1f7843d3a7"
# Version: 1.0.0
# Author: Sebastian Pereira
# Purpose: Автоматически чинить часть "risky" проблем с минимальным риском:
#   - logger f-strings -> printf-style
#   - psycopg2 execute f-strings/конкатенации -> параметризация
#   - subprocess(..., shell=True) -> shell=False + argv (через shlex.split для простых строк)
#   - Остальное (open 'w', сложные shell-строки) — генерировать *.patch-подсказки, не трогая код
# Logs: /storage/emulated/0/Download/project_44/Logs

import os, sys, re, json, argparse, pathlib, io
from datetime import datetime, UTC
import ast
from typing import List, Tuple, Optional

LOG_DIR = os.path.expanduser('/storage/emulated/0/Download/project_44/Logs')
os.makedirs(LOG_DIR, exist_ok=True)

PY_EXTS = {".py"}
EXCLUDE_RE = re.compile(r"/(\.git|\.hg|\.svn|\.venv|venv|node_modules|__pycache__|site-packages|dist-packages|build|dist|\.backup)/")

SHELL_METAS = set("|&;><*?$`~")

def is_py(p: pathlib.Path) -> bool:
    return p.suffix.lower() in PY_EXTS

def iter_targets(paths: List[str]) -> List[pathlib.Path]:
    out = []
    for root in paths:
        rp = pathlib.Path(os.path.expanduser(root))
        if not rp.exists(): continue
        for p in rp.rglob("*.py"):
            if p.is_file() and not EXCLUDE_RE.search(str(p)):
                out.append(p)
    return out

def read_jsonl_paths(jsonl_paths: List[str]) -> List[str]:
    acc = set()
    for lp in jsonl_paths:
        try:
            with open(lp, "r", encoding="utf-8") as f:
                for line in f:
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    if isinstance(obj, dict) and obj.get("risky"):
                        acc.add(obj.get("path",""))
        except Exception:
            continue
    return [p for p in acc if p.endswith(".py") and os.path.exists(p)]

def ensure_import(module: str, name: Optional[str], tree: ast.AST) -> Tuple[ast.AST, bool]:
    """Гарантирует наличие import module (или from module import name). Возвращает (tree, changed)."""
    changed = False
    has = False
    for n in tree.body if isinstance(tree, ast.Module) else []:  # type: ignore
        if isinstance(n, ast.Import):
            for a in n.names:
                if a.name == module:
                    has = True
        if isinstance(n, ast.ImportFrom):
            if n.module == module and (name is None or any(a.name == name for a in n.names)):
                has = True
    if not has:
        ins = ast.Import(names=[ast.alias(name=module)])
        tree.body.insert(0, ins)  # type: ignore
        changed = True
    return tree, changed

# ---------- Fixers ----------
LOG_LEVELS = {"debug","info","warning","error","critical","exception"}

class LoggerFStringFixer(ast.NodeTransformer):
    changed: bool
    def __init__(self):
        super().__init__()
        self.changed = False
    def visit_Call(self, node: ast.Call):
        self.generic_visit(node)
        if isinstance(node.func, ast.Attribute) and node.args:
            if isinstance(node.func.value, ast.Name) and node.func.attr in LOG_LEVELS:
                first = node.args[0]
                if isinstance(first, ast.JoinedStr):
                    parts = []
                    args = []
                    for v in first.values:
                        if isinstance(v, ast.Str):
                            parts.append(v.s.replace("%","%%"))
                        elif isinstance(v, ast.FormattedValue):
                            parts.append("%s")
                            args.append(v.value)
                        else:
                            return node
                    fmt = ast.Constant(value="".join(parts))
                    node.args = [fmt] + args + node.args[1:]
                    self.changed = True
        return node

class SQLParamFixer(ast.NodeTransformer):
    """Превращает cur.execute(f"...{x}...",) или конкатенации в параметризованный вызов.
       Ограничения: все подстановки должны быть простыми (Name/Attribute/Subscript).
    """
    changed: bool
    def __init__(self):
        super().__init__()
        self.changed = False

    @staticmethod
    def _allowed_expr(expr: ast.AST) -> bool:
        return isinstance(expr, (ast.Name, ast.Attribute, ast.Subscript))

    @staticmethod
    def _flatten_binop_str(expr: ast.AST) -> Optional[List[ast.AST]]:
        # Разворачивает "a + b + c" в список узлов, если это цепочка Add
        seq = []
        def rec(e):
            if isinstance(e, ast.BinOp) and isinstance(e.op, ast.Add):
                rec(e.left); rec(e.right)
            else:
                seq.append(e)
        rec(expr)
        return seq

    def _build_param_call(self, node: ast.Call, sql_text: str, params: List[ast.AST]) -> ast.Call:
        # Если уже есть параметры (len(args) >= 2), не трогаем — возможно уже параметризовано
        if len(node.args) >= 2:
            return node
        fmt_arg = ast.Constant(value=sql_text)
        if len(params) == 1:
            param_tuple = ast.Tuple(elts=[params[0]], ctx=ast.Load())
        else:
            param_tuple = ast.Tuple(elts=params, ctx=ast.Load())
        node.args = [fmt_arg, param_tuple]
        self.changed = True
        return node

    def visit_Call(self, node: ast.Call):
        self.generic_visit(node)
        # Ищем *.execute / executemany
        attr = node.func
        if not isinstance(attr, ast.Attribute): return node
        if attr.attr not in ("execute","executemany"): return node
        if not node.args: return node
        first = node.args[0]

        # f-string
        if isinstance(first, ast.JoinedStr):
            sql_parts = []
            params = []
            for v in first.values:
                if isinstance(v, ast.Str):
                    sql_parts.append(v.s)
                elif isinstance(v, ast.FormattedValue) and self._allowed_expr(v.value):
                    sql_parts.append("%s")
                    params.append(v.value)
                else:
                    return node  # сложный случай — пропускаем
            sql_text = "".join(sql_parts)
            return self._build_param_call(node, sql_text, params)

        # конкатенации строк + простые выражения
        if isinstance(first, ast.BinOp):
            seq = self._flatten_binop_str(first)
            if not seq: return node
            sql_parts = []; params = []
            for e in seq:
                if isinstance(e, ast.Str):
                    sql_parts.append(e.s)
                elif self._allowed_expr(e):
                    sql_parts.append("%s"); params.append(e)
                else:
                    return node
            sql_text = "".join(sql_parts)
            return self._build_param_call(node, sql_text, params)

        return node

class SubprocessShellFixer(ast.NodeTransformer):
    """Меняет shell=True -> False, и строковый cmd без метасимволов -> shlex.split(cmd)."""
    changed: bool
    need_shlex: bool
    def __init__(self):
        super().__init__()
        self.changed = False
        self.need_shlex = False

    @staticmethod
    def _has_meta(s: str) -> bool:
        return any(ch in SHELL_METAS for ch in s)

    def visit_Call(self, node: ast.Call):
        self.generic_visit(node)
        if not isinstance(node.func, ast.Attribute): return node
        if not isinstance(node.func.value, ast.Name): return node
        if node.func.value.id != "subprocess": return node
        if node.func.attr not in {"run","Popen","call","check_output"}: return node

        # Найти shell=True
        kw_shell = None
        for kw in node.keywords or []:
            if kw.arg == "shell":
                kw_shell = kw; break
        if not kw_shell: return node
        if not (isinstance(kw_shell.value, ast.Constant) and kw_shell.value.value is True):
            return node

        # Первый позиционный аргумент
        if not node.args: 
            # без args — просто выключим shell
            kw_shell.value = ast.Constant(value=False)
            self.changed = True
            return node

        arg0 = node.args[0]
        # case 1: уже список — просто shell=False
        if isinstance(arg0, (ast.List, ast.Tuple)):
            kw_shell.value = ast.Constant(value=False)
            self.changed = True
            return node

        # case 2: строка без метасимволов
        if isinstance(arg0, ast.Constant) and isinstance(arg0.value, str):
            s = arg0.value
            if not self._has_meta(s):
                # subprocess.run(shlex.split("cmd ..."), shell=False)
                self.need_shlex = True
                node.args[0] = ast.Call(func=ast.Attribute(value=ast.Name(id="shlex", ctx=ast.Load()), attr="split", ctx=ast.Load()),
                                        args=[ast.Constant(value=s)], keywords=[])
                kw_shell.value = ast.Constant(value=False)
                self.changed = True
                return node

        # иначе — слишком сложно; выпишем подсказку позже, оставим как есть
        return node

# ---------- I/O helpers ----------
def atomic_write_text(path: pathlib.Path, data: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.parent / (".tmp." + path.name)
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(data); f.flush(); os.fsync(f.fileno())
    os.replace(tmp, path)

def backup(original: pathlib.Path, ts: str):
    relroot = original
    # ищем корневой из аргументов
    # положим бэкап рядом в .backup/<ts>/...
    root = pathlib.Path(os.path.expanduser("~"))
    try:
        # попытка найти общий корень: берем две директории вверх
        root = original.parents[2]
    except Exception:
        pass
    bdir = root / ".backup" / ts
    bpath = bdir / original.name
    bdir.mkdir(parents=True, exist_ok=True)
    if not bpath.exists():
        bpath.write_text(original.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")

def apply_fixers(pyfile: str) -> dict:
    src_p = pathlib.Path(pyfile)
    src = src_p.read_text(encoding="utf-8", errors="replace")
    try:
        tree = ast.parse(src, filename=pyfile, type_comments=True)
    except SyntaxError as e:
        return {"path": pyfile, "error": f"syntax: {e}"}

    changed = False
    info = {"path": pyfile, "fixed": [], "patches": []}

    # 1) logger f-strings
    lf = LoggerFStringFixer()
    tree = lf.visit(tree); ast.fix_missing_locations(tree)
    if lf.changed:
        changed = True; info["fixed"].append("logger_fstr")

    # 2) SQL param
    sf = SQLParamFixer()
    tree = sf.visit(tree); ast.fix_missing_locations(tree)
    if sf.changed:
        changed = True; info["fixed"].append("sql_param")

    # 3) subprocess shell=True
    shf = SubprocessShellFixer()
    tree = shf.visit(tree); ast.fix_missing_locations(tree)
    if shf.changed:
        changed = True; info["fixed"].append("shell_true->argv")
        if shf.need_shlex:
            tree, imp_changed = ensure_import("shlex", None, tree)
            changed = changed or imp_changed

    # emit new code if changed
    if changed:
        try:
            new_src = ast.unparse(tree)  # python 3.9+
        except Exception as e:
            return {"path": pyfile, "error": f"unparse: {e}"}
        ts = datetime.now(UTC).strftime('%Y%m%d_%H%M%S')
        # backup в тот же каталог .bak.<ts>.имя.py
        bak = src_p.parent / f".bak.autofix.{ts}.{src_p.name}"
        bak.write_text(src, encoding="utf-8")
        atomic_write_text(src_p, new_src)
        return info

    # не изменяли — возможно, выпишем патчи (open 'w' и сложные shell)
    # open 'w' подсказка:
    if re.search(r'open\([^)]*["\'],\s*["\']w["\']', src):
        patch = (
"""# PATCH SUGGESTION (atomic write helper):
import os, tempfile
def write_atomic(path, data):
    d = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(prefix=".tmp.", dir=d)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(data); f.flush(); os.fsync(f.fileno())
    os.replace(tmp, path)
# replace: open(PATH,'w') ... -> write_atomic(PATH, data)
""")
        info["patches"].append("open_write_atomic")
        # кладём рядом файл-подсказку
        (src_p.parent / (src_p.stem + ".open_write.patch.py")).write_text(patch, encoding="utf-8")

    # сложная shell-команда подсказка
    if re.search(r'subprocess\.(run|Popen|call|check_output)\([^)]*shell\s*=\s*True', src) and "shell_true->argv" not in info["fixed"]:
        patch = (
"""# PATCH SUGGESTION (quote & /bin/sh -c):
import shlex, subprocess
cmd = "cmd1 ARG | cmd2"  # build with shlex.quote(user_input) for variables!
safe = "/bin/sh -c " + shlex.quote(cmd)
subprocess.run(["/bin/sh","-c", cmd], check=True)
# or better: subprocess.run(["cmd1", arg, ...], check=True)
""")
        info["patches"].append("shell_quote")
        (src_p.parent / (src_p.stem + ".shell.patch.py")).write_text(patch, encoding="utf-8")

    return info

def main():
    ap = argparse.ArgumentParser(description="Risky Autofixer: AST-патчи для SQL/logger/shell")
    ap.add_argument("paths", nargs="*", help="Каталоги или файлы .py")
    ap.add_argument("--from-jsonl", nargs="*", help="Пути к JSONL отчётам (omega/autofix), чтобы ограничить список")
    ap.add_argument("--apply-all", action="store_true", help="Игнорировать JSONL фильтр и пройтись по дереву")
    ap.add_argument("--log", default=os.path.join(LOG_DIR, f"wz_risky_autofix_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.jsonl"))
    args = ap.parse_args()

    targets: List[str] = []
    if args.from_jsonl and not args.apply_all:
        targets = read_jsonl_paths(args.from_jsonl)
    else:
        # сканируем переданные пути
        if not args.paths:
            args.paths = [os.path.expanduser("~/wheelzone-script-utils"), "/opt/wz-api"]
        for p in args.paths:
            pth = pathlib.Path(os.path.expanduser(p))
            if pth.is_file() and is_py(pth):
                targets.append(str(pth))
            elif pth.is_dir():
                targets.extend([str(x) for x in iter_targets([str(pth)])])

    targets = sorted(set(targets))
    total = len(targets)
    fixed = 0
    hints = 0
    errs  = 0

    with open(args.log, "w", encoding="utf-8") as logf:
        for path in targets:
            try:
                info = apply_fixers(path)
            except Exception as e:
                logf.write(json.dumps({"lvl":"ERROR","path":path,"err":repr(e)})+"\n")
                errs += 1
                continue

            if "error" in info:
                errs += 1
                logf.write(json.dumps({"lvl":"ERROR","path":path,"err":info["error"]}, ensure_ascii=False)+"\n")
                continue

            if info.get("fixed"):
                fixed += 1
            if info.get("patches"):
                hints += 1

            logf.write(json.dumps({"lvl":"INFO","path":path,"fixed":info.get("fixed",[]),"patches":info.get("patches",[])}, ensure_ascii=False)+"\n")

    print(json.dumps({"lvl":"INFO","summary":{"total":total,"fixed":fixed,"patch_hints":hints,"errors":errs,"log":args.log}}, ensure_ascii=False))

if __name__ == "__main__":
    main()
