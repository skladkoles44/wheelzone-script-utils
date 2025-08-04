#!/usr/bin/env bash
# end.sh — запуск ChatEnd-анализа и логирования
set -euo pipefail
source ~/wz-wiki/tools/chatend/helpers.sh
cd ~/chatgpt_memory_core || exit 1
echo "🔍 Запускается end…"
~/wz-wiki/tools/chatend/generate_chatend_summary.sh > ~/wzbuffer/tmp_chatend_output.log
echo "✅ ChatEnd завершён. Лог записан в ~/wzbuffer/tmp_chatend_output.log"
