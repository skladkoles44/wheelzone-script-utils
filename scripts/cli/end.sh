#!/usr/bin/env bash
# uuid: 2025-08-26T13:19:22+03:00-1897095000
# title: end.sh
# component: .
# updated_at: 2025-08-26T13:19:22+03:00

# end.sh — запуск ChatEnd-анализа и логирования
set -euo pipefail
source ~/wz-wiki/tools/chatend/helpers.sh
cd ~/chatgpt_memory_core || exit 1
echo "🔍 Запускается end…"
~/wz-wiki/tools/chatend/generate_chatend_summary.sh > ~/wzbuffer/tmp_chatend_output.log
echo "✅ ChatEnd завершён. Лог записан в ~/wzbuffer/tmp_chatend_output.log"
