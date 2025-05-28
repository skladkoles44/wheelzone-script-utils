#!/usr/bin/env bash
# backup_docs.sh — скрипт инкрементального бэкапа документации “стройки”

# Путь к документу
DOC_PATH="$HOME/wheelzone/auto-framework/ALL/docs/стройка_портал_документация.md"

# Удалённые хранилища (папка docs)
REMOTE_PATH="lllBackUplll-WheelZone/docs"

# Синхронизация в Google Drive
rclone copy "$DOC_PATH" gdrive:/$REMOTE_PATH

# Синхронизация в Yandex.Disk
rclone copy "$DOC_PATH" yandex_wheelzone:/$REMOTE_PATH
