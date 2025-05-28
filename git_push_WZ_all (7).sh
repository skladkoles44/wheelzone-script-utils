#!/data/data/com.termux/files/usr/bin/bash

HASH_LOG="$HOME/.wz_hash_log"
TMP_HASH="$HOME/tmp/wz_current_hashes.tmp"
LOG_FILE="$HOME/wheelzone/bootstrap_tool/logs/git_add_debug.log"
> "$TMP_HASH"
> "$LOG_FILE"

scan_dirs=(
  "$HOME/storage/downloads"
  "$HOME/storage/downloads/project_44/Termux"
  "$HOME/wheelzone/auto-framework/ALL"
)

cd "$HOME/wheelzone/auto-framework" || exit 1

for dir in "${scan_dirs[@]}"; do
  find "$dir" -type f \( -name "WZ_*.md" -o -name "*.md" -o -name "*.txt" \) | while read -r file; do
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
  file=$(echo "$line" | cut -d' ' -f2- | xargs)

  echo "Путь перед добавлением: [$file]" >> "$LOG_FILE"

  if ! grep -q "$file" "$HASH_LOG" || ! grep "$file" "$HASH_LOG" | grep -q "$hash"; then
    full_file="$HOME/$file"
    cp "$full_file" "$file" 2>/dev/null
    if git ls-files "$file" --error-unmatch >/dev/null 2>&1; then
      git add "$file" 2>>"$LOG_FILE"
      changes+=("$file")
    else
      echo "Пропущен (вне git): $file" >> "$LOG_FILE"
    fi
  fi
done < "$TMP_HASH"

if [ "${#changes[@]}" -gt 0 ]; then
  msg="autopush: обновление файлов ($(date '+%Y-%m-%d %H:%M'))"
  git commit -m "$msg"
  git push
fi
