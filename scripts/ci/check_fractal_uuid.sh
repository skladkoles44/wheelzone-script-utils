#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:22+03:00-1752436345
# title: check_fractal_uuid.sh
# component: .
# updated_at: 2025-08-26T13:19:22+03:00

set -Eeuo pipefail
# shellcheck disable=SC1091
source ".wz/fractal_uuid_utils.sh" || { echo "[WZ][WARN] utils missing"; exit 0; }

MAX_DEPTH="${MAX_DEPTH:-12}"

missing=()
while IFS= read -r -d '' f; do
  path_ignored "$f" && continue
  has_uuid "$f" && continue || missing+=( "$f" )
done < <(find_targets .)

if [ "${#missing[@]}" -gt 0 ]; then
  printf '[WZ][FAIL] Missing fractal_uuid (%d):\n' "${#missing[@]}"
  printf '%s\n' "${missing[@]}"
  exit 42
fi
printf '\033[1;92m[WZ][OK] fractal_uuid headers present\033[0m\n'
