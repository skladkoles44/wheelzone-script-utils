#!/bin/bash
# uuid: 2025-08-26T13:19:45+03:00-3609653416
# title: test_wz_ai_rule.bash
# component: .
# updated_at: 2025-08-26T13:19:46+03:00

echo "[TEST] Dry-run check..."
OUTPUT=$(~/wheelzone-script-utils/scripts/wz_ai_rule.sh --dry-run "Test" 2>&1)
if [[ "$OUTPUT" == *"DRY RUN"* ]]; then
  echo "✅ PASS"
  exit 0
else
  echo "❌ FAIL"
  exit 1
fi
