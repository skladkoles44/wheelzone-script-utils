#!/usr/bin/env bash
# WZ :: Space Audit (Termux)
# version: 1.0.0

set -Eeuo pipefail; IFS=$'\n\t'

echo "=== [WZ] Disk usage audit: \$HOME (user space) ==="
du -sh "$HOME"/* 2>/dev/null | sort -h | tail -n 10

echo
echo "=== [WZ] Disk usage audit: \$PREFIX (Termux packages) ==="
du -sh "$PREFIX"/* 2>/dev/null | sort -h | tail -n 10

echo
echo "=== [WZ] Largest files (top 10) ==="
find "$HOME" "$PREFIX" -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head -n 10 | awk '{printf "%s MB\t%s\n", $1/1024/1024, $2}'
