#!/data/data/com.termux/files/usr/bin/python3
import sys, json, pandas as pd, sqlite3, os
"""
Импорт из CSV/Excel/JSON в БД (пример на SQLite).
Поведение:
- авто-детект формата по расширению
- базовая нормализация колонок
- UPSERT по полю sku (CREATE TABLE IF NOT EXISTS)
Usage: import_stock_items.py <input_path> <db_path:~/data/stock.db>
"""
def load_table(path: str) -> pd.DataFrame:
    p = path.lower()
    if p.endswith((".csv", ".tsv")): return pd.read_csv(path)
    if p.endswith((".xlsx", ".xls")): return pd.read_excel(path)
    if p.endswith((".json",)): return pd.read_json(path)
    raise SystemExit(f"Unsupported format: {path}")

def normalize(df: pd.DataFrame) -> pd.DataFrame:
    df = df.rename(columns={c: c.strip().lower() for c in df.columns})
    must = ["sku","name","brand","qty"]
    for c in must:
        if c not in df.columns: df[c] = None
    df["sku"] = df["sku"].astype(str).str.strip()
    df["qty"] = pd.to_numeric(df["qty"], errors="coerce").fillna(0).astype(int)
    return df

def ensure_schema(cx):
    cx.execute("""
CREATE TABLE IF NOT EXISTS stock_items(
  sku TEXT PRIMARY KEY,
  name TEXT,
  brand TEXT,
  qty INTEGER,
  meta JSON
)""")

def upsert(cx, rows):
    for r in rows:
        cx.execute("""
INSERT INTO stock_items(sku,name,brand,qty,meta)
VALUES(?,?,?,?,json(?))
ON CONFLICT(sku) DO UPDATE SET
  name=excluded.name,
  brand=excluded.brand,
  qty=excluded.qty,
  meta=excluded.meta
""", (r["sku"], r["name"], r["brand"], r["qty"], json.dumps(r)))

def main():
    if len(sys.argv) < 3:
        print("Usage: import_stock_items.py <input_path> <db_path>", file=sys.stderr)
        sys.exit(2)
    src, db = sys.argv[1], os.path.expanduser(sys.argv[2])
    df = normalize(load_table(src))
    cx = sqlite3.connect(db)
    ensure_schema(cx)
    upsert(cx, df.to_dict(orient="records"))
    cx.commit(); cx.close()
    print(f"OK import rows={len(df)} db={db}")

if __name__ == "__main__": main()
