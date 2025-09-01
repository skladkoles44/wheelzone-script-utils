#!/usr/bin/env bash
# WZ :: Space Strong Clean (Termux)
# version: 1.0.0

set -Eeuo pipefail; IFS=$'\n\t'

echo "=== [WZ] Strong Clean Started ==="

# 1) Git оптимизация
for repo in "$HOME/wz-wiki" "$HOME/bash_build/bash"; do
  if [ -d "$repo/.git" ]; then
    echo "[WZ] git gc in $repo..."
    (cd "$repo" && git gc --aggressive --prune=now >/dev/null 2>&1 || true)
  fi
done

# 2) Сжатие больших логов
for d in "$HOME/wzbuffer" "$HOME/logs"; do
  [ -d "$d" ] || continue
  while IFS= read -r -d '' f; do
    echo "[WZ] compressing $f..."
    xz -T0 -zf "$f" || true
  done < <(find "$d" -type f \( -name '*.log' -o -name '*.txt' \) -size +50M -print0 2>/dev/null)
done

# 3) Чистка кэшей пакетов
echo "[WZ] Cleaning apt/pkg caches..."
rm -rf "$PREFIX/var/cache/apt/"* "$PREFIX/var/lib/apt/lists/"* 2>/dev/null || true

if command -v pip >/dev/null 2>&1; then
  echo "[WZ] Cleaning pip cache..."
  pip cache purge >/dev/null 2>&1 || true
fi

if command -v npm >/dev/null 2>&1; then
  echo "[WZ] Cleaning npm cache..."
  npm cache clean --force >/dev/null 2>&1 || true
fi

# 4) Итог
echo
echo "=== [WZ] Disk usage after clean ==="
du -sh "$HOME/wzbuffer" "$HOME/wz-wiki" "$HOME/logs" "$PREFIX/lib" 2>/dev/null | sort -h
echo "=== [WZ] Strong Clean Done ==="
