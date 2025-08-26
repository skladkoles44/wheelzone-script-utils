#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:19:33+03:00-4055883817
# title: test_log_manager.sh
# component: .
# updated_at: 2025-08-26T13:19:33+03:00

# 🔁 Автотест log_manager.sh (Termux-совместимый)

TEST_DIR="$HOME/tmp/wz_log_test"
mkdir -p "$TEST_DIR"

# Экспорт переменных окружения
export LOG_SOURCE="$TEST_DIR/logs"
export LOG_DEST="$TEST_DIR/archive"
export SYNC_LOG="$TEST_DIR/test.log"
export LOCK_FILE="$TEST_DIR/lock"

rm -rf "$TEST_DIR"/*

echo "=== Подготовка тестовых логов ==="
mkdir -p "$LOG_SOURCE"
echo '{"test":"data1"}' > "$LOG_SOURCE/notion_log.ndjson"
echo '{"mock":"response1"}' > "$LOG_SOURCE/notion_mock_responses.ndjson"

echo -e "\n=== Тест 1: Архивация логов ==="
~/wheelzone-script-utils/scripts/log_manager.sh
ls -lh "$LOG_DEST"

echo -e "\n=== Тест 2: Проверка блокировки ==="
( ~/wheelzone-script-utils/scripts/log_manager.sh & )
sleep 1
~/wheelzone-script-utils/scripts/log_manager.sh

echo -e "\n=== Тест 3: Очистка старых логов ==="
touch -d "8 days ago" "$LOG_DEST/notion_log_old.ndjson"
~/wheelzone-script-utils/scripts/log_manager.sh

echo -e "\n=== Итоговые результаты ==="
ls -lh "$LOG_DEST"
echo -e "\nЛог выполнения:"
cat "$SYNC_LOG"
