#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

for f in ~/wz-wiki/tools/*.md; do
  # Пропускаем, если уже есть поле
  if grep -qiE '^fractal_uuid:' "$f"; then
    continue
  fi

  UUID="$(uuidgen | tr 'A-Z' 'a-z')"
  CREATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  UPDATED="$CREATED"

  if head -1 "$f" | grep -q '^---$'; then
    # Вставляем в существующий front-matter
    awk -v uuid="$UUID" '
      BEGIN{in_hdr=0; inserted=0}
      NR==1 && $0=="---"{in_hdr=1; print; next}
      in_hdr && !inserted {
        print "fractal_uuid: " uuid
        print $0
        inserted=1
        next
      }
      {print}
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  else
    # Создаём новый front-matter
    {
      echo '---'
      echo "fractal_uuid: $UUID"
      echo "Created-At: $CREATED"
      echo "Updated-At: $UPDATED"
      echo '---'
      cat "$f"
    } > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

# Унификация стиля: Fractal-UUID -> fractal_uuid
sed -i 's/^Fractal-UUID:/fractal_uuid:/I' ~/wz-wiki/tools/*.md

echo "[OK] Автофикс fractal_uuid завершён."
