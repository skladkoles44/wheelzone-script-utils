#!/usr/bin/env bash
# ⚗️ WZ Experimental :: AI Rule Generator v0.1
set -Eeuo pipefail
ROOT="$HOME/wz-wiki/WZChatEnds"
OUT="$HOME/wz-wiki/experiments/exp_ai_rule.yaml"

say(){ printf "[WZ-EXP] %s\n" "$*"; }

: > "$OUT"
for f in "$ROOT"/*.yaml; do
  grep -qiE 'token|nginx|uuid' "$f" || continue
  say "Найден кандидат: $f"
  cat >> "$OUT" <<YAML
- candidate_rule:
    source: $(basename "$f")
    keyword_match: true
    status: PROPOSED
    fractal_uuid: $(uuidgen)
YAML
done
say "Файл предложений создан: $OUT"
