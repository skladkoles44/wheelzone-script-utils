#!/bin/bash
# wz_notify.sh — универсальный нотификатор (Telegram / Termux / Notion)

MESSAGE="$1"
CHANNEL="${2:-termux}"  # По умолчанию Termux

log() {
  printf '{"ts":"%s","channel":"%s","msg":"%s"}\n' "$(date +%s)" "$CHANNEL" "$MESSAGE" >> "$HOME/wzbuffer/logs/notify.json"
}

notify_termux() {
  command -v termux-notification >/dev/null && termux-notification --title "WZ Notify" --content "$MESSAGE" --priority high
  command -v termux-toast >/dev/null && termux-toast "$MESSAGE"
  command -v termux-vibrate >/dev/null && termux-vibrate -d 200
  log
}

notify_telegram() {
  bash "$HOME/wheelzone-script-utils/wz_notify_push.sh" "$MESSAGE"
  log
}

notify_notion() {
  python3 "$HOME/wheelzone-script-utils/scripts/notion/notion_log_entry.py" --message "$MESSAGE" --type "notify"
  log
}

case "$CHANNEL" in
  termux) notify_termux ;;
  telegram) notify_telegram ;;
  notion) notify_notion ;;
  *) echo "[ERROR] Неизвестный канал: $CHANNEL" >&2; exit 1 ;;
esac
