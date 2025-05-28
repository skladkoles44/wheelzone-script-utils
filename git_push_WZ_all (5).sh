#!/data/data/com.termux/files/usr/bin/bash

HASH_LOG="$HOME/.wz_hash_log"
TMP_HASH="$HOME/tmp/wz_current_hashes.tmp"
> "$TMP_HASH"

scan_dirs=(
  "$HOME/storage/downloads"
  "$HOME/storage/downloads/project_44/Termux"
  "$HOME/wheelzone/auto-framework/ALL"
)

cd "$HOME/wheelzone/auto-framework" || exit 1

for dir in "${scan_dirs[@]}"; do
  find "$dir" -type f \( -name "WZ_*.md" -o -name "*.md" -o -name "*.txt" \) | while read -r file; do
    # Пропустить файлы вне git-репозитория
    if ! git ls-files "$file" --error-unmatch >/dev/null 2>&1; then
      continue
    fi

    # Удаление абсолютного префикса пути
    rel_path="${file##*/wheelzone/auto-framework/}"
    [ -z "$rel_path" ] && continue

    hash=$(sha256sum "$file" | awk '{print $1}')
    echo "$hash  $rel_path" >> "$TMP_HASH"
  done
done

changes=()
while read -r line; do
  hash=$(echo "$line" | awk '{print $1}')
  file=$(echo "$line" | cut -d' ' -f2-)
  if ! grep -q "$file" "$HASH_LOG" || ! grep "$file" "$HASH_LOG" | grep -q "$hash"; then
    cp "$HOME/$file" "$file" 2>/dev/null
    git add "$file" 2>/dev/null
    changes+=("$file")
  fi
done < "$TMP_HASH"

if [ "${#changes[@]}" -gt 0 ]; then
  msg="autopush: обновление файлов ($(date '+%Y-%m-%d %H:%M'))"
  git commit -m "$msg"
  git push
fi
