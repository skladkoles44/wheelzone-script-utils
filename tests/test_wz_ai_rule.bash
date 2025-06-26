#!/bin/bash
echo "[TEST] Dry-run check..."
OUTPUT=$(~/wheelzone-script-utils/scripts/wz_ai_rule.sh --dry-run "Test" 2>&1)
if [[ "$OUTPUT" == *"DRY RUN"* ]]; then
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
