#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Новые термины: idempotent (безопасно повторять), ENV (файл переменных окружения).
SCRIPT="$HOME/wheelzone-script-utils/mobile/wz_env_collect.sh"

# Кандидаты-источники (в порядке приоритета)
CANDS=(
  "$HOME/wzbuffer/search_rclone_files_with_creds.txt"
  "$HOME/wzbuffer/search_rclone_file_matrix.tsv"
  "$HOME/wzbuffer/search_rclone_results.txt"
  "/data/data/com.termux/files/home/wzbuffer/search_rclone_gdrive_audit.txt"
)

pick=""
for f in "${CANDS[@]}"; do
  if [ -s "$f" ]; then pick="$f"; break; fi
done

if [ -z "${pick}" ]; then
  printf '[wz_env_run][ERROR] Не найден ни один непустой источник аудита.\n' >&2
  printf 'Проверь наличие файлов в ~/wzbuffer/:\n - search_rclone_files_with_creds.txt\n - search_rclone_file_matrix.tsv\n - search_rclone_results.txt\n' >&2
  printf 'Либо укажи вручную: AUDIT_PATH=/полный/путь %s [--apply]\n' "$SCRIPT" >&2
  exit 1
fi

export AUDIT_PATH="$pick"
printf '[wz_env_run] Использую AUDIT_PATH=%s\n' "$AUDIT_PATH"

# Шаг 1: REVIEW (формирует ~/wzbuffer/tokens_found_for_review.txt)
"$SCRIPT"

printf '\n[hint] Отредактируй ~/wzbuffer/tokens_found_for_review.txt (KEY=VALUE, убери лишнее), затем:\n'
printf '       AUDIT_PATH=%q %q --apply\n' "$AUDIT_PATH" "$SCRIPT"
