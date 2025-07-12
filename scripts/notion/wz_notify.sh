#!/data/data/com.termux/files/usr/bin/bash
# wz_notify.sh v7.4.0 — Уведомления: Notion, Termux, Telegram (Termux-ready, fallback-proof)

set -eo pipefail
shopt -s nullglob

### === CONFIG ===
readonly VERSION="7.4.0"
readonly NOTION_SCRIPT="$HOME/wheelzone-script-utils/scripts/notion/notion_log_entry.py"
readonly TELEGRAM_SCRIPT="$HOME/wheelzone-script-utils/wz_notify_push.sh"
readonly TERMUX_TMP="/data/data/com.termux/files/usr/tmp"
readonly LOG_DIR="$HOME/wzbuffer/logs"
readonly PERMALOG_DIR="$HOME/wheelzone-script-utils/logs"
readonly LOCKFILE="$TERMUX_TMP/wz_notify.lock"
readonly PYTHON_EXEC=$(command -v python3.11 || command -v python3 || echo "/dev/null")

mkdir -p "$TERMUX_TMP/logs" "$LOG_DIR" "$PERMALOG_DIR" || {
  echo "[ERROR] mkdir failed: $TERMUX_TMP/logs, $LOG_DIR, $PERMALOG_DIR" >&2
  exit 1
}

### === ARGUMENTS ===
TYPE=""; TITLE=""; MESSAGE=""; CHANNEL=""; PERMALOG=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift ;;
    --title) TITLE="$2"; shift ;;
    --message) MESSAGE="$2"; shift ;;
    --channel) CHANNEL="$2"; shift ;;
    --permalog) PERMALOG=true ;;
    --help) echo "$0 — универсальный логгер уведомлений"; exit 0 ;;
    --version) echo "$VERSION"; exit 0 ;;
    *) echo "[ERROR] Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ -z "$TYPE" || -z "$TITLE" || -z "$MESSAGE" ]] && {
  echo "[ERROR] Не заданы обязательные поля: --type, --title, --message" >&2
  exit 1
}

### === INTERNAL ===
generate_event_id() {
  if command -v iconv >/dev/null; then
    printf '%s' "$TITLE" | iconv -t ascii//TRANSLIT//IGNORE 2>/dev/null |
      tr -dc 'a-zA-Z0-9 ' | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//' |
      tr ' ' '-' | head -c 48
  else
    echo "ev-$(date +%s)"
  fi
}
EVENT="$(generate_event_id)"
SOURCE="wz_notify.sh"

### === CHANNELS ===
notify_notion() {
  [[ -f "$NOTION_SCRIPT" ]] || { echo "[ERROR] Notion script not found"; return 1; }
  [[ -x "$PYTHON_EXEC" ]] || { echo "[ERROR] Python not found"; return 1; }

  "$PYTHON_EXEC" "$NOTION_SCRIPT" \
    --type "$TYPE" --name "$TITLE" --event "$EVENT" --source "$SOURCE" --message "$MESSAGE" \
    >> "$TERMUX_TMP/logs/notion.log" 2>> "$TERMUX_TMP/logs/notion-errors.log"
}

notify_termux() {
  if command -v termux-notification >/dev/null; then
    termux-notification --title "$TITLE" --content "$MESSAGE" --priority high \
      || echo "[ERROR] termux-notification failed" >&2
  fi
  command -v termux-toast >/dev/null && termux-toast "$TITLE" || true
  command -v termux-vibrate >/dev/null && termux-vibrate -d 200 || true
}

notify_telegram() {
  [[ -f "$TELEGRAM_SCRIPT" ]] || { echo "[ERROR] Telegram script not found"; return 1; }
  bash "$TELEGRAM_SCRIPT" "$MESSAGE"
}

log_json() {
  printf '{"ts":"%s","type":"%s","title":"%s","msg":"%s"}\n' \
    "$(date +%FT%T)" "$TYPE" "$TITLE" "$MESSAGE" >> "$LOG_DIR/notify.json"
}

log_permalog() {
  printf '%s — [%s] %s\n' "$(date +%FT%T)" "$TYPE" "$TITLE" >> "$PERMALOG_DIR/permalog.log"
  printf "- type: %s\n  title: %s\n  ts: %s\n" "$TYPE" "$TITLE" "$(date +%FT%T)" >> "$LOG_DIR/permalog.yaml"
}

### === MAIN ===
main() {
  exec 200>"$LOCKFILE"
  flock -n 200 || { echo "[ERROR] Скрипт уже работает" >&2; exit 1; }

  termux-wake-lock
  trap 'termux-wake-unlock; flock -u 200' EXIT

  case "$CHANNEL" in
    notion) notify_notion || echo "[WARN] Notion failed" >&2 ;;
    telegram) notify_telegram ;;
    termux|"") notify_termux ;;
    *) echo "[ERROR] Неизвестный канал: $CHANNEL" >&2; exit 1 ;;
  esac

  log_json
  $PERMALOG && log_permalog
}

main &
disown
