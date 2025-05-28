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

    rel_path="${file##*/wheelzone/auto-framework/}"
    rel_path=$(echo "$rel_path" | xargs)
    [ -z "$rel_path" ] && continue

    hash=$(sha256sum "$file" | awk '{print $1}')
    echo "$hash  $rel_path" >> "$TMP_HASH"
  done
done

changes=()
while read -r line; do
  hash=$(echo "$line" | awk '{print $1}')
  file=$(echo "$line" | cut -d' ' -f2-)
  clean_file=$(echo "$file" | xargs)
  if ! grep -q "$clean_file" "$HASH_LOG" || ! grep "$clean_file" "$HASH_LOG" | grep -q "$hash"; then
    cp "$HOME/$clean_file" "$clean_file" 2>/dev/null
    git add "$clean_file" 2>/dev/null
    changes+=("$clean_file")
  fi
done < "$TMP_HASH"

if [ "${#changes[@]}" -gt 0 ]; then
  msg="autopush: обновление файлов ($(date '+%Y-%m-%d %H:%M'))"
  git commit -m "$msg"
  git push
fi
