#!/data/data/com.termux/files/usr/bin/bash
# === Комплексный тест wz_chatend.sh v3.1 ===

find_script_path() {
    local possible_paths=(
        "$HOME/wheelzone-script-utils/scripts/chatend/wz_chatend.sh"
        "$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"
        "$HOME/.local/bin/wz_chatend.sh"
    )
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    echo "Не удалось найти wz_chatend.sh в стандартных расположениях!" >&2
    return 1
}

TEST_DIR="$HOME/wzbuffer/chatend_test"
LOG_FILE="$TEST_DIR/test.log"
SCRIPT_PATH=$(find_script_path)
INSIGHTS_FILE="$HOME/wzbuffer/tmp_insights.txt"

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ Ошибка: основной скрипт не найден!" >&2
    echo "Искали по путям:" >&2
    find_script_path >&2
    exit 1
fi

init_test() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    : > "$LOG_FILE"

    cat > "$TEST_DIR/main.md" <<EOF_MAIN
# Основной ChatEnd

[[FRACTAL:$HOME/wzbuffer/chatend_test/nested.md]]
TODO:
- Проверить все режимы работы
- Добавить тест Telegram

DONE:
- Создан комплексный тест
EOF_MAIN

    cat > "$TEST_DIR/nested.md" <<EOF_NESTED
# Вложенный ChatEnd

INSIGHT:
Нужно тестировать все компоненты системы
EOF_NESTED

    cat > "$INSIGHTS_FILE" <<EOF_AUTO
TODO: Автоматически сгенерированная задача
DONE: Завершенный автотест
INSIGHT: Важное наблюдение
EOF_AUTO
}

test_fractal() {
    echo -e "\n🔵 Тестируем --fractal" | tee -a "$LOG_FILE"
    if ! bash "$SCRIPT_PATH" --fractal "$TEST_DIR/main.md" 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка в --fractal режиме" | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

test_auto() {
    echo -e "\n🟢 Тестируем --auto" | tee -a "$LOG_FILE"
    if ! bash "$SCRIPT_PATH" --auto 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка в --auto режиме" | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

test_telegram() {
    echo -e "\n🟣 Тестируем --tg-test" | tee -a "$LOG_FILE"
    if ! bash "$SCRIPT_PATH" --tg-test 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка Telegram-теста" | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

check_results() {
    echo -e "\n📜 Результаты тестирования:" | tee -a "$LOG_FILE"
    echo -e "\n📂 Созданные файлы:" | tee -a "$LOG_FILE"
    find "$HOME/wz-wiki/WZChatEnds" -name "*.md" -mmin -5 -ls 2>/dev/null | tee -a "$LOG_FILE"

    local errors=$(grep -ci "error\|fail\|warning" "$LOG_FILE")
    if (( errors > 0 )); then
        echo -e "\n⚠️ Найдено $errors ошибок в логах" | tee -a "$LOG_FILE"
        grep -i "error\|fail\|warning" "$LOG_FILE" | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

main() {
    init_test
    echo "🔧 Начинаем комплексное тестирование..." | tee -a "$LOG_FILE"
    echo "Используемый скрипт: $SCRIPT_PATH" | tee -a "$LOG_FILE"

    test_fractal
    test_auto
    test_telegram

    if check_results; then
        echo -e "\n✅ Все тесты пройдены успешно!" | tee -a "$LOG_FILE"
    else
        echo -e "\n❌ Обнаружены проблемы в тестах" | tee -a "$LOG_FILE"
        exit 1
    fi
}

main
