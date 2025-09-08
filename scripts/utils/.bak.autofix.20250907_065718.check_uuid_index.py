"""
UUID Docs Validator (PROD-optimized, WBP, etalon)
CLI: --check-links --check-mermaid --check-meta --check-all
"""
import os, re, sys, argparse, json
from functools import lru_cache
CACHE_MAXSIZE = int(os.environ.get('WZ_CACHE_MAXSIZE', '32'))
try:
    import yaml
except Exception:
    print('ERROR: pyyaml is required', file=sys.stderr)
    sys.exit(2)
RE_MD_VERSION = re.compile('\\*\\*Версия:\\*\\*\\s*([0-9]+\\.[0-9]+\\.[0-9]+)')
RE_MD_STATUS = re.compile('\\*\\*Статус:\\*\\*\\s*([A-Z]+)')
RE_ERD_ENTITY = re.compile('\\b[A-Z_]{3,}\\b')
MERMAID_BLOCK_RE = re.compile('```mermaid\\s+(.+?)```', re.S | re.I)
JSON_LOG = os.environ.get('WZ_CI_JSON_LOG') == '1'

def jlog(level, msg, **f):
    if JSON_LOG:
        print(json.dumps({'level': level, 'msg': msg, **f}, ensure_ascii=False))
    else:
        m = {'ok': '✅', 'warn': '⚠️', 'err': '❌'}.get(level, '•')
        print(f'{m} {msg}', file=sys.stderr if level in ('warn', 'err') else sys.stdout)

def fail(msg, **f):
    jlog('err', msg, **f)
    sys.exit(1)

def ok(msg, **f):
    jlog('ok', msg, **f)

def _cache_key(p):
    return os.path.abspath(os.path.normpath(p))

@lru_cache(maxsize=CACHE_MAXSIZE)
def safe_read_text_cached(p):
    if not os.path.isfile(p):
        fail('Файл не найден', path=p)
    with open(p, 'r', encoding='utf-8') as f:
        return f.read()

def safe_read_text(p):
    key = _cache_key(p)
    if os.environ.get('WZ_DOC_CACHE_DISABLE') == '1':
        return safe_read_text_cached.__wrapped__(key)
    return safe_read_text_cached(key)

class ParsedMD:
    __slots__ = ('text', 'mermaid_blocks', 'erd_text', 'meta')

    @classmethod
    @lru_cache(maxsize=max(4, CACHE_MAXSIZE // 4))
    def from_file(cls, path: str):
        return cls(safe_read_text(path))

    def __init__(self, text):
        self.text = text
        self.mermaid_blocks = MERMAID_BLOCK_RE.findall(text)
        self.erd_text = next((b for b in self.mermaid_blocks if b.strip().splitlines()[0].strip().lower() == 'erdiagram'), '')
        self.meta = {'version': RE_MD_VERSION.search(text).group(1) if RE_MD_VERSION.search(text) else '', 'status': RE_MD_STATUS.search(text).group(1) if RE_MD_STATUS.search(text) else ''}

def check_links(parsed, md_path):
    need = ('uuid_orchestrator_brief.md', '../registry/uuid_policy.yaml', '../registry/uuid_orchestrator.yaml')
    missing = [r for r in need if f']({r})' not in parsed.text]
    if missing:
        fail('Нет обязательных ссылок: ' + ', '.join(missing), file=md_path)
    ok('Ссылки OK')

def check_mermaid(parsed, md_path):
    if not parsed.mermaid_blocks:
        fail('Нет Mermaid-блоков', file=md_path)
    if parsed.erd_text:
        tokens = set(RE_ERD_ENTITY.findall(parsed.erd_text))
        req = ('DEVICES', 'SESSIONS', 'UUID_POOL', 'UUID_ACCESS_LOG', 'UUID_RECEIPTS', 'UUID_REPLACEMENTS', 'UUID_ARTIFACTS')
        lack = [e for e in req if e not in tokens]
        if lack:
            fail('ERD отсутствуют сущности: ' + ', '.join(lack))
    ok('Mermaid/ERD OK')

def check_meta(parsed, policy_path):
    y = yaml.safe_load(safe_read_text(policy_path))
    pv = str(y.get('version', '') or '')
    ps = str(y.get('status', '') or '').upper()
    if pv and parsed.meta['version'] and (pv != parsed.meta['version']):
        fail(f"Версия: index={parsed.meta['version']} vs policy={pv}")
    if ps and parsed.meta['status'] and (ps != parsed.meta['status']):
        fail(f"Статус: index={parsed.meta['status']} vs policy={ps}")
    ok('Версия/статус OK')

def _sqlite_advisory(db_path: str):
    try:
        import sqlite3
        with sqlite3.connect(db_path) as con:
            cur = con.cursor()
            tables = {r[0].lower() for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table'")}

            def has_uuid_idx(t):
                try:
                    return any(('uuid' in r[1].lower() for r in cur.execute('PRAGMA index_list(%s)', (t,))))
                except Exception:
                    return False
            bad = [t for t in ('uuid_pool', 'uuid_access_log', 'uuid_receipts', 'uuid_replacements') if t in tables and (not has_uuid_idx(t))]
            if bad:
                warn('SQLite: отсутствуют индексы по uuid', tables=','.join(bad))
    except Exception:
        pass

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sqlite-advisory', default=os.environ.get('WZ_SQLITE_ADVISORY'))
    ap.add_argument('--check-links', action='store_true')
    ap.add_argument('--check-mermaid', action='store_true')
    ap.add_argument('--check-meta', action='store_true')
    ap.add_argument('--check-all', action='store_true')
    ap.add_argument('--policy', default='registry/uuid_orchestrator.yaml')
    ap.add_argument('index_md', nargs='?')
    a = ap.parse_args()
    if not a.index_md:
        fail('Укажите путь к docs/index_uuid.md')
    if a.sqlite_advisory:
        _sqlite_advisory(a.sqlite_advisory)
    parsed = ParsedMD.from_file(a.index_md)
    if a.check_all:
        a.check_links = a.check_mermaid = a.check_meta = True
    if a.check_links:
        check_links(parsed, a.index_md)
    if a.check_mermaid:
        check_mermaid(parsed, a.index_md)
    if a.check_meta:
        check_meta(parsed, a.policy)
    ok('Все проверки пройдены')
    sys.exit(0)
if __name__ == '__main__':
    main()