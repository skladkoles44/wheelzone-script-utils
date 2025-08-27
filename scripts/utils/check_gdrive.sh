#!/usr/bin/env bash
# man: name=check_gdrive
# man: section=1
# man: version=1.1
# man: date=2025-08-27
# man: author=WheelZone Automation Stack
# man: synopsis=check_gdrive.sh [--remote NAME] [--json|--yaml|--text] [--warn-days N] [--min-free-gb N]
# man: description=Quick audit of an rclone remote: checks availability, shows about info, lists top-level dirs, and inspects OAuth token expiry.
# man: options=--remote NAME      use given remote (default: gdrive)
# man: options=--json             JSON output
# man: options=--yaml             YAML output
# man: options=--text             human-readable output
# man: options=--warn-days N      warning threshold before token expiry (days)
# man: options=--min-free-gb N    warning threshold for free space (GiB)
# man: options=-h, --help         show help
# man: exit=0   everything is fine
# man: exit=20  warnings (low space or expiring token)
# man: exit=10  rclone not found
# man: exit=11  remote not found
# man: exit=12  remote about failed
# man: exit=13  lsd failed

set -Eeuo pipefail

# ===== Конфиг по умолчанию =====
REMOTE="gdrive"             # можно переопределить аргументом/флагом
FORMAT="text"               # text | json | yaml
WARN_DAYS=7                 # предупредить, если токен истекает раньше, чем через N дней
MIN_FREE_GB=5               # предупредить, если свободного места < N GiB

# ===== Временные файлы =====
ERRF="$(mktemp)"
TOKF="$(mktemp)"
ABOUTF="$(mktemp)"
SUMF="$(mktemp)"
trap 'rm -f "$ERRF" "$TOKF" "$ABOUTF" "$SUMF"' EXIT

ok()  { printf "\033[1;92m[WZ]\033[0m %s\n" "$*"; }
err() { printf "\033[1;91m[ERR]\033[0m %s\n" "$*" >&2; }
hdr() { printf "\033[1;92m%s\033[0m\n" "$*"; }  # жирно-зелёный заголовок

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--remote NAME] [--json|--yaml|--text] [--warn-days N] [--min-free-gb N]
Defaults: --remote gdrive --text --warn-days ${WARN_DAYS} --min-free-gb ${MIN_FREE_GB}

Exit codes:
  0  OK
 10  rclone не найден
 11  remote не найден
 12  нет доступа к remote (about)
 13  ошибка чтения каталога
 20  предупреждение по месту или сроку токена
USAGE
}

# ===== Парсинг флагов =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)       REMOTE="${2:-}"; shift 2 ;;
    --json)         FORMAT="json"; shift ;;
    --yaml)         FORMAT="yaml"; shift ;;
    --text)         FORMAT="text"; shift ;;
    --warn-days)    WARN_DAYS="${2:-7}"; shift 2 ;;
    --min-free-gb)  MIN_FREE_GB="${2:-5}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *)              if [[ -z "${REMOTE_SET:-}" && "$1" != "" ]]; then REMOTE="$1"; REMOTE_SET=1; shift; else shift; fi ;;
  esac
done

hdr "== GDrive audit: ${REMOTE} =="

# 1) rclone установлен?
if ! command -v rclone >/dev/null 2>&1; then
  err "rclone не установлен. Установите: pkg install rclone"
  exit 10
fi

# 2) remote существует?
if ! rclone listremotes | grep -q "^${REMOTE}:"; then
  err "Remote '${REMOTE}' не найден. Запустите: rclone config"
  exit 11
fi

# 3) about (место)
ok "📊 Информация о ${REMOTE}:"
if ! rclone about "${REMOTE}:" >"$ABOUTF" 2>"$ERRF"; then
  err "Нет доступа: $(<"$ERRF")"
  exit 12
fi
cat "$ABOUTF" | tee -a "$SUMF" >/dev/null || true

# 4) список каталогов (первые 5)
ok "📂 Первые папки в корне:"
if ! rclone lsd "${REMOTE}:" 2>"$ERRF" | head -n 5 | tee -a "$SUMF"; then
  err "Ошибка при чтении: $(<"$ERRF")"
  exit 13
fi

# 5) токен (expiry)
ok "🔐 Проверка OAuth-токена:"
if rclone config show "${REMOTE}" 2>/dev/null | sed -n 's/^[[:space:]]*token[[:space:]]*=\s*//p' > "$TOKF"; then
  if [[ ! -s "$TOKF" ]]; then
    echo "expiry: n/a (token не найден)" | tee -a "$SUMF"
  fi
else
  echo "expiry: n/a (нет доступа к конфигу)" | tee -a "$SUMF"
fi

# 6) Сборка итоговой структуры и вывод в выбранном формате
PYOUT="$(
python3 - <<'PY' "$ABOUTF" "$TOKF" "$WARN_DAYS" "$MIN_FREE_GB" "$FORMAT" "$REMOTE"
import sys, re, json, datetime
about_path, tok_path, warn_days_s, min_free_gb_s, fmt, remote = sys.argv[1:7]
warn_days   = int(warn_days_s)
min_free_gb = float(min_free_gb_s)

def parse_about(text: str):
    lines = [ln.strip() for ln in text.strip().splitlines() if ln.strip()]
    data = {"raw": lines, "parsed": {}}
    keys = ("Total","Used","Free","Other","Trashed")
    for k in keys:
        m = next((ln for ln in lines if ln.lower().startswith(k.lower()+":")), None)
        if not m: 
            continue
        m2 = re.search(r":\s*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z]+)", m)
        if m2:
            val, unit = float(m2.group(1)), m2.group(2)
            u = unit.lower()
            if   u in ("gib","gi","g","gb"):     gib = val
            elif u in ("mib","mi","m","mb"):     gib = val/1024.0
            else:                                gib = None
            data["parsed"][k.lower()]={"value":val,"unit":unit,"gib":gib,"line":m}
        else:
            data["parsed"][k.lower()]={"value":None,"unit":None,"gib":None,"line":m}
    return data

def parse_token_expiry(path: str):
    try:
        raw = open(path,"r",encoding="utf-8").read().strip()
        if not raw:
            return {"status":"n/a","expiry":None,"seconds_to_expiry":None}
        if raw.startswith('"') and raw.endswith('"'): raw=raw[1:-1]
        tok=json.loads(raw); exp=tok.get("expiry")
        if not exp: return {"status":"n/a","expiry":None,"seconds_to_expiry":None}
        try:
            expiry=datetime.datetime.fromisoformat(exp.replace('Z','+00:00'))
        except Exception:
            return {"status":"unparsable","expiry":exp,"seconds_to_expiry":None}
        now=datetime.datetime.now(datetime.timezone.utc)
        secs=int((expiry-now).total_seconds())
        return {"status":"ok" if secs>0 else "expired","expiry":expiry.isoformat(),"seconds_to_expiry":secs}
    except Exception as e:
        return {"status":"error","error":str(e),"expiry":None,"seconds_to_expiry":None}

def make_yaml(obj, indent=0):
    sp="  "*indent
    if obj is None: return "null"
    if isinstance(obj,(bool,int,float)): return str(obj).lower() if isinstance(obj,bool) else str(obj)
    if isinstance(obj,str):
        import json as _j, re as _r
        return _j.dumps(obj,ensure_ascii=False) if _r.search(r'[:#\-\[\]\{\},&*!|>\'"\n\r\t]',obj) else obj
    if isinstance(obj,list):
        return "[]"? not obj else "\n".join([sp+"- "+make_yaml(v,indent+1).lstrip() for v in obj])
    if isinstance(obj,dict):
        if not obj: return "{}"
        out=[]
        for k,v in obj.items():
            if isinstance(v,(dict,list)):
                out.append(f"{sp}{k}:")
                child=make_yaml(v,indent+1)
                out.append("\n".join([("  "*(indent+1)+ln) if ln else "" for ln in child.splitlines()]))
            else:
                out.append(f"{sp}{k}: {make_yaml(v,indent)}")
        return "\n".join(out)
    import json as _j; return _j.dumps(obj,ensure_ascii=False)

about_text=open(about_path,"r",encoding="utf-8").read()
about=parse_about(about_text)
token=parse_token_expiry(tok_path)

free_gib=about.get("parsed",{}).get("free",{}).get("gib")
warns=[]
if free_gib is not None and free_gib < min_free_gb:
    warns.append(f"Low free space: {free_gib:.2f} GiB < {min_free_gb} GiB")
if token.get("status")=="expired":
    warns.append("Token expired")
elif isinstance(token.get("seconds_to_expiry"),int):
    days_left=token["seconds_to_expiry"]/86400.0
    if days_left < warn_days:
        warns.append(f"Token expiring soon: ~{days_left:.1f} days")

result={
  "remote":remote,
  "about":about,
  "token":token,
  "thresholds":{"warn_days":warn_days,"min_free_gib":min_free_gb},
  "warnings":warns,
  "status":"ok" if not warns else "warn"
}

if fmt=="json":
    import json; print(json.dumps(result,ensure_ascii=False,indent=2))
elif fmt=="yaml":
    print(make_yaml(result))
else:
    print("== SUMMARY ==")
    p=about.get("parsed",{})
    def show(k):
        d=p.get(k,{})
        if d.get("value") is not None:
            return f"{k.capitalize()}: {d['value']} {d['unit']}" + (f" (~{d['gib']:.2f} GiB)" if d.get('gib') is not None else "")
        return f"{k.capitalize()}: n/a"
    print(show("free")); print(show("used")); print(show("total"))
    if token.get("status") in ("ok","expired"):
        secs=token.get("seconds_to_expiry")
        if isinstance(secs,int) and secs>0:
            d=secs//86400; h=(secs%86400)//3600; m=(secs%3600)//60
            print(f"Token: {token['status']} (expiry {token.get('expiry')} ~{d}d {h}h {m}m)")
        else:
            print(f"Token: {token['status']} (expiry {token.get('expiry')})")
    else:
        print(f"Token: {token.get('status')}")
    if warns:
        print("WARNINGS:"); [print(f"- {w}") for w in warns]
print("::RETURNCODE::"+("0" if not warns else "20"))
PY
)"

RET=$(printf "%s\n" "$PYOUT" | awk -F'::RETURNCODE::' 'NF>1{print $2}' | tail -n1)
OUT=$(printf "%s\n" "$PYOUT" | sed 's/::RETURNCODE::[0-9]\{1,2\}//g')

if [[ "$FORMAT" == "text" ]]; then
  hdr "== SUMMARY =="
  printf "%s\n" "$OUT"
else
  printf "%s\n" "$OUT"
fi

if command -v termux-clipboard-set >/dev/null 2>&1; then
  printf "%s" "$OUT" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' | termux-clipboard-set || true
  ok "Результат скопирован в буфер обмена."
fi

exit "${RET:-0}"
