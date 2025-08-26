#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:08+03:00-3192323387
# title: wz_ai_autolog_demo.sh
# component: .
# updated_at: 2025-08-26T13:19:08+03:00

# wz_ai_autolog_demo.sh — Примеры вызовов autolog
set -e

base=~/wheelzone-script-utils/scripts/ai/wz_ai_autolog.sh

$base "echo-test" echo "🧠 Привет от AI autolog"
$base "uptime" uptime
$base "whoami" whoami
$base "tree" tree ~/wheelzone-script-utils/scripts | head -n 10
