#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:02+03:00-2281280203
# title: git_push_WZ_all (2).sh
# component: .
# updated_at: 2025-08-26T13:20:02+03:00


HASH_LOG="$HOME/.wz_hash_log"
TMP_HASH="$HOME/tmp/wz_current_hashes.tmp"
> "$TMP_HASH"

sanitize_path() {
  echo "$1" | sed 's|^[[:space:]]*||;s|[[:space:]]*$||'
}

scan_dirs=(
  "$HOME/storage/downloads"
  "$HOME/storage/downloads/project_44/Termux"
  "$HOME/wheelzone/auto-framework/ALL"
)

cd "$HOME/wheelzone/auto-framework" || exit 1

for dir in "${scan_dirs[@]}"; do
  find "$dir" -type f \( -name "WZ_*.md" -o -name "*.md" -o -name "*.txt" \) | while read -r file; do
    rel_path=$(realpath --relative-to="$HOME/wheelzone/auto-framework" "$file" 2>/dev/null)
    rel_path=$(sanitize_path "$rel_path")
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
