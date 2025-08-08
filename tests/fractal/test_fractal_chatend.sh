#!/data/data/com.termux/files/usr/bin/bash
# Тест фрактальной обработки v1.0

# Конфигурация
TEST_DIR="$HOME/wzbuffer/chatend_test"
LOG_FILE="$TEST_DIR/test.log"
SCRIPT_PATH="$HOME/wheelzone-script-utils/scripts/cli/wz_chatend.sh"
OUTPUT_FILE="$TEST_DIR/test_output.txt"
FRACTAL_LOG="$HOME/wzbuffer/fractal_processing.log"

# Инициализация
init_test() {
    echo "🧹 Подготовка тестовой среды..."
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    : > "$FRACTAL_LOG"
    
    # Создаем тестовые файлы
    cat > "$TEST_DIR/main.md" <<'EOM'
# Основной ChatEnd

[[FRACTAL:~/wzbuffer/chatend_test/nested.md]]

TODO:
- Проверить фрактальную обработку
- Протестировать вложенность

DONE:
- Настроена тестовая среда
EOM

    cat > "$TEST_DIR/nested.md" <<'EON'
# Вложенный ChatEnd

INSIGHT:
Фрактальная структура работает корректно
EON
}

# Запуск теста
run_test() {
    echo -e "\n🔵 Запуск фрактальной обработки..."
    bash "$SCRIPT_PATH" --fractal "$TEST_DIR/main.md" > "$OUTPUT_FILE" 2>> "$LOG_FILE"
    local exit_code=$?
    
    echo "📊 Результаты:"
    echo "Код завершения: $exit_code"
    
    # Проверка результатов
    local passed=0
    local failed=0
    
    echo -e "\n🔍 Проверка вывода:"
    if grep -qF "# Вложенный ChatEnd" "$OUTPUT_FILE"; then
        echo "🟢 Вложенный файл обработан"
        ((passed++))
    else
        echo "🔴 Вложенный файл не найден"
        ((failed++))
    fi
    
    if grep -qF "Фрактальная структура работает корректно" "$OUTPUT_FILE"; then
        echo "🟢 Контент вложенного файла присутствует"
        ((passed++))
    else
        echo "🔴 Контент вложенного файла отсутствует"
        ((failed++))
    fi
    
    echo -e "\n📜 Лог обработки:"
    grep -E "Обработка:|Файл не" "$FRACTAL_LOG" | sed 's/^/  /'
    
    echo -e "\n📊 Итог:"
    echo "Успешных проверок: $passed"
    echo "Неудачных проверок: $failed"
    
    return $failed
}

# Главная функция
main() {
    init_test
    run_test
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        echo -e "\n🎉 Все тесты пройдены успешно!"
    else
        echo -e "\n❌ Обнаружены проблемы в тестах"
    fi
    
    exit $result
}

main
