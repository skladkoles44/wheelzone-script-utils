#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:45+03:00-2060765104
# title: wz_sync_rules.sh
# component: .
# updated_at: 2025-08-26T13:19:45+03:00

# WheelZone Rule Registry Sync v2.1.2 — Fractal CLI Edition

set -eo pipefail
[[ ! -x "$HOME/wheelzone-script-utils/scripts/utils/generate_uuid.sh" ]] && echo '[ERR] UUID generator missing' && exit 1
shopt -s nullglob nocasematch

# === Константы ===
readonly WZ_DIR="$HOME/wz-wiki"
readonly RULES_DIR="$WZ_DIR/rules"
readonly REGISTRY="$WZ_DIR/registry/registry.yaml"
readonly LOG="$HOME/.cache/wz_ai/sync_rules.log"
readonly MAX_SIZE=100000

# === Цветной вывод ===
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
die()   { echo -e "${RED}[ERR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" >&2; exit 1; }
log()   { echo -e "${GREEN}[+]${NC} $(date '+%H:%M:%S') $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $(date '+%H:%M:%S') $1"; }

# === YAML валидация ===
validate_yaml() {
    python3 -c "
import sys, yaml
try:
    with open('$1') as f:
        yaml.safe_load(f)
    sys.exit(0)
except Exception as e:
    print(f'Invalid YAML: {str(e)}', file=sys.stderr)
    sys.exit(1)
"
}

# === Основной sync ===
sync_registry() {
    log "Начинаю синхронизацию"
    local temp_registry="$REGISTRY.tmp"
    cp "$REGISTRY" "$REGISTRY.bak" 2>/dev/null || echo "rules: []" > "$REGISTRY.bak"

    python3 -c "
import sys, yaml, os
from pathlib import Path

f_in = '$REGISTRY.bak'
f_out = '$temp_registry'

def load_registry():
    try:
        with open(f_in) as f:
            data = yaml.safe_load(f) or {}
        if not isinstance(data, dict):
            raise ValueError('Invalid registry format')
        return data
    except:
        return {'rules': []}

registry = load_registry()
existing = {r['slug'] for r in registry.get('rules', []) if isinstance(r, dict)}

for file in Path('$RULES_DIR').glob('*.md'):
    try:
        if file.stat().st_size > $MAX_SIZE:
            print(f'[WARN] Пропущен {file.name} (большой размер)', file=sys.stderr)
            continue

        with file.open() as f:
            lines = [next(f) for _ in range(10)]

        meta = {}
        for line in lines:
            if line.startswith('id:'): meta['id'] = line.split(':',1)[1].strip()
            elif line.startswith('slug:'): meta['slug'] = line.split(':',1)[1].strip()
            elif line.startswith('created:'): meta['created'] = line.split(':',1)[1].strip()

        if not all(k in meta for k in ('id', 'slug')):
            print(f'[WARN] Пропущен {file.name} (неполные метаданные)', file=sys.stderr)
            continue

        if meta['slug'] in existing:
            print(f'[INFO] Уже в реестре: {meta["slug"]}', file=sys.stderr)
            continue

        registry['rules'].append({
            'id': meta['id'],
            'slug': meta['slug'],
            'created': meta.get('created', '')
        })
        print(f'[+] Добавлен: {meta["slug"]}', file=sys.stderr)

    except Exception as e:
        print(f'[WARN] Ошибка файла {file.name}: {str(e)}', file=sys.stderr)

if $DRY:
    print('=== DRY RUN ===', file=sys.stderr)
else:
    with open(f_out, 'w') as f:
        yaml.safe_dump(registry, f, allow_unicode=True, sort_keys=False)
" >> "$LOG" 2>&1

    [[ "$DRY" -eq 0 ]] && validate_yaml "$temp_registry" && mv "$temp_registry" "$REGISTRY"
    log "Синхронизация завершена"
}

# === CLI ===
show_help() {
    echo -e "${GREEN}WZ Sync Rules CLI v2.1.2${NC}"
    echo "Usage:"
    echo "  $0 --sync         # Синхронизация"
    echo "  $0 --dry-run      # Тестовый режим"
    echo "  $0 --validate     # Проверка YAML"
    echo "  $0 --help         # Подсказка"
    exit 0
}

main() {
    [[ ! -d "$RULES_DIR" ]] && die "Директория $RULES_DIR не найдена"
    mkdir -p "$(dirname "$LOG")" "$(dirname "$REGISTRY")"
    DRY=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --sync) shift ;;
            --dry-run) DRY=1; shift ;;
            --validate) validate_yaml "$REGISTRY"; exit $? ;;
            --help|-h) show_help ;;
            *) die "Неизвестный параметр: $1" ;;
        esac
    done

    sync_registry
}

main "$@"
