#!/usr/bin/env bash
# wz_notify.sh — отправка уведомлений о событиях WZ
set -euo pipefail

TYPE=""
NAME=""
DESC=""
TAGS=""
STATUS=""

for arg in "$@"; do
  case $arg in
    --type=*) TYPE="${arg#*=}" ;;
    --name=*) NAME="${arg#*=}" ;;
    --desc=*) DESC="${arg#*=}" ;;
    --tags=*) TAGS="${arg#*=}" ;;
    --status=*) STATUS="${arg#*=}" ;;
  esac
done

echo -e "📡 Уведомление:\nТип: $TYPE\nИмя: $NAME\nОписание: $DESC\nТеги: $TAGS\nСтатус: $STATUS"
# Здесь может быть отправка в Telegram, Notion и др.
