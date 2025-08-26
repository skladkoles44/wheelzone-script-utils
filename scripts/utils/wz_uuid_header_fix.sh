#!/usr/bin/env bash
# uuid: $(date -Iseconds)-bootstrap-fix-uuid-headers
# title: WZ :: UUID header fixer (shell scripts)
# version: 1.0.0
# component: utils
# description: Add minimal "uuid:" header to shell scripts if missing (keeps shebang).
# updated_at: $(date -Iseconds)
set -Eeuo pipefail; IFS=$'\n\t'

MODE="dry"   # dry|write
ROOT="${1:-.}"; shift || true
case "${1:-}" in --write) MODE="write";; --dry-run|"") ;; *) ;; esac

cd "$ROOT"

# try to source canonical generator
if [ -f "$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_bridge.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/wheelzone-script-utils/scripts/utils/wz_uuid_bridge.sh" || true
fi

gen_uuid() {
  if command -v generate_fractal_uuid >/dev/null 2>&1; then
    generate_fractal_uuid "uuid-header:$(basename "$1")"
  else
    # fallback (unique-enough)
    printf '%s\n' "$(date -Iseconds)-$(cksum <"$1" | awk '{print $1}')" 
  fi
}

is_shell() {
  # *.sh OR has shebang with sh/bash/dash
  case "$1" in
    *.sh) return 0;;
    *) head -n1 -- "$1" | grep -Eq '^#!.*/(ba|z|)sh(\s|$)' && return 0 || return 1;;
  esac
}

needs_header() {
  head -n 15 -- "$1" | grep -qi 'uuid:' && return 1 || return 0
}

fix_one() {
  local f="$1"
  local bn comp she tmp uuid
  bn="$(basename "$f")"
  comp="$(dirname "$f" | cut -d/ -f1)"
  tmp="$(mktemp)"
  uuid="$(gen_uuid "$f")"

  # preserve shebang if present
  if head -n1 -- "$f" | grep -q '^#!'; then
    {
      head -n1 -- "$f"
      printf '# uuid: %s\n# title: %s\n# component: %s\n# updated_at: %s\n\n' "$uuid" "$bn" "$comp" "$(date -Iseconds)"
      tail -n +2 -- "$f"
    } > "$tmp"
  else
    {
      printf '# uuid: %s\n# title: %s\n# component: %s\n# updated_at: %s\n\n' "$uuid" "$bn" "$comp" "$(date -Iseconds)"
      cat -- "$f"
    } > "$tmp"
  fi
  chmod --reference="$f" "$tmp" 2>/dev/null || true
  mv -- "$tmp" "$f"
}

# build candidate list from git (tracked) + executable scripts (untracked)
mapfile -t FILES < <(
  { git ls-files -z -- ':!:*.min.*' | xargs -0 -I{} echo "{}"; \
    find . -type f -perm -0100 -not -path '*/.git/*' -print; } | sort -u
)

COUNT=0
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  is_shell "$f" || continue
  needs_header "$f" || continue
  case "$MODE" in
    dry)
      printf '[DRY] %s\n' "$f"
      ;;
    write)
      fix_one "$f"
      printf '[FIXED] %s\n' "$f"
      COUNT=$((COUNT+1))
      ;;
  esac
done

if [ "$MODE" = "write" ]; then
  printf 'Total fixed: %d\n' "$COUNT"
fi
