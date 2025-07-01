#!/usr/bin/env bash
# generate_metadata_block.sh v0.1 — генератор блока метаданных (yaml/json)
set -euo pipefail
IFS=$'\n\t'

VERSION="0.1"
MAX_FILE_SIZE=$((10 * 1024 * 1024)) # 10MB

show_help() {
    cat <<EOH
Usage: $(basename "$0") --file FILE [--format yaml|json] [--uuid-strategy content|random]

Required:
  --file FILE        Path to input file

Options:
  --format FORMAT    Output format (yaml|json, default: yaml)
  --uuid-strategy STRATEGY  UUID generation method (content|random, default: content)
  --version          Show version
  --help             Show this help
EOH
}

validate_file() {
    [[ -e "$1" ]] || { echo "❌ Error: Path does not exist: $1" >&2; exit 1; }
    [[ -f "$1" ]] || { echo "❌ Error: Not a regular file: $1" >&2; exit 1; }
    [[ -r "$1" ]] || { echo "❌ Error: Cannot read file: $1" >&2; exit 1; }
    
    local file_size
    if ! file_size=$(stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null); then
        echo "❌ Error: Failed to get file size" >&2
        exit 1
    fi

    if (( file_size > MAX_FILE_SIZE )); then
        echo "❌ Error: File size exceeds limit (max ${MAX_FILE_SIZE} bytes)" >&2
        exit 1
    fi
}

generate_slug() {
    local content="$1"
    grep -m1 '^SLUG:' <<<"$content" | 
    awk -F: '{print substr($0, index($0,$2))}' |
    iconv -t ascii//TRANSLIT 2>/dev/null |
    tr -cd '[:alnum:] _-' |
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' |
    tr ' ' '_' | tr -s '_' |
    head -c 64
}

safe_uuidgen() {
    if command -v uuidgen >/dev/null; then
        uuidgen || (echo "00000000-0000-0000-0000-000000000000" && return 1)
    else
        python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null ||
        echo "00000000-0000-0000-0000-000000000000"
    fi
}

generate_metadata() {
    local file="$1" format="$2" uuid_strategy="$3"
    local content slug filename date_now hash uuid

    if ! content=$(head -c $((MAX_FILE_SIZE + 1)) "$file" 2>/dev/null); then
        echo "❌ Error: Failed to read file content" >&2
        exit 1
    fi

    if [[ $(stat -c%s "$file" 2>/dev/null || stat -f%z "$file") -gt $MAX_FILE_SIZE ]]; then
        echo "⚠️ Warning: File was truncated to ${MAX_FILE_SIZE} bytes" >&2
    fi

    slug=$(generate_slug "$content")
    slug=${slug:-no-slug}
    filename=$(basename -- "$file")
    date_now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%d")
    hash=$(sha256sum "$file" | cut -d' ' -f1)

    if [[ "$uuid_strategy" == "content" ]]; then
        if command -v python3 >/dev/null; then
            uuid=$(python3 -c "
import uuid, sys
try:
    print(uuid.uuid5(uuid.NAMESPACE_URL, open(sys.argv[1], 'rb').read().decode('utf-8', errors='replace')))
except:
    print(uuid.uuid4())
" "$file" 2>/dev/null) || uuid=$(safe_uuidgen)
        else
            uuid=$(safe_uuidgen)
        fi
    else
        uuid=$(safe_uuidgen)
    fi

    case "$format" in
        json)
            if command -v jq >/dev/null; then
                jq -n \
                    --arg uuid "$uuid" \
                    --arg slug "$slug" \
                    --arg filename "$filename" \
                    --arg date "$date_now" \
                    --arg hash "$hash" \
                    --arg version "$VERSION" \
                    '{
                        uuid: $uuid,
                        slug: $slug,
                        filename: $filename,
                        date: $date,
                        sha256: $hash,
                        generator: ($version | "generate_metadata_block.sh v" + .)
                    }' || echo '{"error":"Failed to generate JSON metadata"}'
            else
                printf '{\n  "uuid": "%s",\n  "slug": "%s",\n  "filename": "%s",\n  "date": "%s",\n  "sha256": "%s",\n  "generator": "generate_metadata_block.sh v%s"\n}\n' \
                       "$uuid" "$slug" "$filename" "$date_now" "$hash" "$VERSION"
            fi
            ;;
        yaml|*)
            printf "---\n"
            printf "uuid: %s\n" "$uuid"
            printf "slug: %s\n" "$slug"
            printf "filename: \"%s\"\n" "$filename"
            printf "date: \"%s\"\n" "$date_now"
            printf "sha256: \"%s\"\n" "$hash"
            printf "generator: generate_metadata_block.sh v%s\n" "$VERSION"
            printf "---\n"
            ;;
    esac
}

main() {
    local file="" format="yaml" uuid_strategy="content"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) 
                [[ -n "$2" ]] || { echo "❌ Error: --file requires a value" >&2; exit 1; }
                file="$2"
                shift 2
                ;;
            --format)
                [[ -n "$2" ]] || { echo "❌ Error: --format requires a value" >&2; exit 1; }
                format="${2,,}"
                shift 2
                ;;
            --uuid-strategy)
                [[ -n "$2" ]] || { echo "❌ Error: --uuid-strategy requires a value" >&2; exit 1; }
                uuid_strategy="${2,,}"
                shift 2
                ;;
            --version)
                echo "v$VERSION"
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                echo "❌ Error: Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                echo "❌ Error: Positional arguments are not supported" >&2
                show_help
                exit 1
                ;;
        esac
    done

    [[ -z "$file" ]] && { echo "❌ Error: --file is required" >&2; show_help; exit 1; }
    validate_file "$file"

    case "$format" in
        yaml|json) ;;
        *) echo "❌ Error: Invalid format. Use yaml or json" >&2; exit 1 ;;
    esac

    case "$uuid_strategy" in
        content|random) ;;
        *) echo "❌ Error: Invalid UUID strategy. Use content or random" >&2; exit 1 ;;
    esac

    generate_metadata "$file" "$format" "$uuid_strategy"
}

main "$@"
