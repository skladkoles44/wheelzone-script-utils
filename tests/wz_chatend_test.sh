#!/data/data/com.termux/files/usr/bin/bash
# === Комплексный тест wz_chatend.sh v3.2 ===

# Автоматически определяем путь к скрипту
find_script_path() {
    local possible_paths=(
        "$HOME/wheelzone-script-utils/scripts/chatend/wz_chatend.sh"
        "$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    echo "Не удалось найти wz_chatend.sh!" >&2
    return 1
}

# Конфигурация
TEST_DIR="$HOME/wzbuffer/chatend_test"
LOG_FILE="$TEST_DIR/test.log"
SCRIPT_PATH=$(find_script_path)
INSIGHTS_FILE="$HOME/wzbuffer/tmp_insights.txt"

# Проверяем, что нашли скрипт
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ Ошибка: основной скрипт не найден!" >&2
    exit 1
fi

init_test() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    : > "$LOG_FILE"
    
    # Создаем тестовые файлы с абсолютными путями
    cat > "$TEST_DIR/main.md" <<EOF_MAIN
# Основной ChatEnd

[[FRACTAL:$TEST_DIR/nested.md]]

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

    # Для --auto режима
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
    echo "Телеграм тест запущен в $(date)" >> "$LOG_FILE"
    if bash "$SCRIPT_PATH" --tg-test 2>&1 | tee -a "$LOG_FILE"; then
        echo "Telegram test completed" >> "$LOG_FILE"
        return 0
    else
        echo "❌ Ошибка Telegram-теста" | tee -a "$LOG_FILE"
        return 1
    fi
}

check_results() {
    local error_count=0
    
    echo -e "\n📜 Результаты тестирования:" | tee -a "$LOG_FILE"
    
    # Проверяем созданные файлы
    echo -e "\n📂 Созданные файлы:" | tee -a "$LOG_FILE"
    local created_files=$(find "$HOME/wz-wiki/WZChatEnds" -name "*.md" -mmin -5 2>/dev/null | wc -l)
    if (( created_files < 2 )); then
        echo "⚠️ Создано слишком мало файлов ($created_files)" | tee -a "$LOG_FILE"
        ((error_count++))
    else
        find "$HOME/wz-wiki/WZChatEnds" -name "*.md" -mmin -5 -ls | tee -a "$LOG_FILE"
    fi
    
    # Проверяем логи на ошибки
    local log_errors=$(grep -ci "error\|fail\|warning" "$LOG_FILE")
    if (( log_errors > 0 )); then
        echo -e "\n⚠️ Найдено $log_errors ошибок в логах" | tee -a "$LOG_FILE"
        grep -i "error\|fail\|warning" "$LOG_FILE" | tee -a "$LOG_FILE"
        ((error_count++))
    fi
    
    return $error_count
}

git_sync() {
    echo -e "\n🔄 Синхронизация с Git..." | tee -a "$LOG_FILE"
    cd ~/wheelzone-script-utils || {
        echo "❌ Не удалось перейти в репозиторий" | tee -a "$LOG_FILE"
        return 1
    }

    COMMIT_MSG="✅ ChatEnd тест: фиксация изменений перед синком"

    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "📝 Обнаружены локальные изменения — подготавливаем коммит..." | tee -a "$LOG_FILE"
        git add -A
        if git diff --cached --name-only | grep -q .; then
            git commit -m "$COMMIT_MSG"
        else
            echo "⚠️ Нет файлов для коммита после git add -A" | tee -a "$LOG_FILE"
        fi
    else
        echo "✅ Нет изменений для коммита" | tee -a "$LOG_FILE"
    fi

    if ! git pull --rebase 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка при git pull (возможно, конфликты)" | tee -a "$LOG_FILE"
        return 1
    fi

    if ! git push 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка при git push" | tee -a "$LOG_FILE"
        return 1
    fi

    echo "✅ Git синхронизирован успешно" | tee -a "$LOG_FILE"
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
    fi
    
    # Синхронизация с Git
    if git_sync; then
        echo "🔄 Git синхронизирован успешно" | tee -a "$LOG_FILE"
    else
        echo "❌ Ошибка синхронизации с Git" | tee -a "$LOG_FILE"
    fi
}

main
