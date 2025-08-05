#!/data/data/com.termux/files/usr/bin/bash
# === Комплексный тест wz_chatend.sh v3.3 ===

# Конфигурация
TEST_DIR="$HOME/wzbuffer/chatend_test"
LOG_FILE="$TEST_DIR/test.log"
SCRIPT_PATH="$HOME/wheelzone-script-utils/scripts/wz_chatend.sh"
INSIGHTS_FILE="$HOME/wzbuffer/tmp_insights.txt"

# Инициализация тестовой среды
init_test() {
    echo "🧹 Подготовка тестовой среды..."
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    cat > "$TEST_DIR/main.md" <<'EOM'
# Основной ChatEnd

[[FRACTAL:$HOME/wzbuffer/chatend_test/nested.md]]

TODO:
- Проверить фрактальную обработку
- Протестировать авторежим

DONE:
- Настроен тестовый сценарий
EOM

    cat > "$TEST_DIR/nested.md" <<'EOM'
# Вложенный ChatEnd

INSIGHT:
Фрактальная структура работает корректно
EOM

    cat > "$INSIGHTS_FILE" <<'EOM'
TODO: Тестовая задача
DONE: Выполненный пункт
INSIGHT: Важное наблюдение
EOM

    : > "$LOG_FILE"
}

check_dependencies() {
    local missing=()
    [[ ! -f "$SCRIPT_PATH" ]] && missing+=("Основной скрипт wz_chatend.sh")
    ! command -v uuidgen >/dev/null && missing+=("uuidgen")
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ Отсутствуют зависимости:"
        printf "  - %s\n" "${missing[@]}"
        exit 1
    fi
}

check_created_files() {
    local pattern="$1"
    local min_count="${2:-1}"
    local files=()
    mapfile -t files < <(find "$HOME/wz-wiki/WZChatEnds" -name "$pattern" -mmin -5 2>/dev/null)
    if [[ ${#files[@]} -lt $min_count ]]; then
        echo "❌ Ошибка: создано недостаточно файлов (${#files[@]} из $min_count)"
        return 1
    fi
    echo "✅ Создано файлов: ${#files[@]}"
    return 0
}

run_tests() {
    local errors=0
    echo -e "\n🔵 Тест 1/3: Фрактальная обработка"
    if ! bash "$SCRIPT_PATH" --fractal "$TEST_DIR/main.md" 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка в фрактальном режиме"
        ((errors++))
    elif grep -q "⚠️ Не найден файл" "$LOG_FILE"; then
        echo "❌ Ошибка: не найден вложенный файл"
        ((errors++))
    else
        echo "✅ Фрактальная обработка завершена"
        check_created_files "fractal-*.md" 2 || ((errors++))
    fi

    echo -e "\n🟢 Тест 2/3: Авторежим"
    if ! bash "$SCRIPT_PATH" --auto 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка в авторежиме"
        ((errors++))
    else
        echo "✅ Авторежим завершен"
        check_created_files "2025-*.md" 1 || ((errors++))
    fi

    echo -e "\n🟣 Тест 3/3: Telegram-интеграция"
    if ! bash "$SCRIPT_PATH" --tg-test 2>&1 | tee -a "$LOG_FILE"; then
        echo "❌ Ошибка Telegram-теста"
        ((errors++))
    elif grep -q "ERROR" "$LOG_FILE"; then
        echo "❌ Ошибка при отправке в Telegram"
        ((errors++))
    else
        echo "✅ Telegram-тест пройден"
    fi

    return $errors
}

git_sync() {
    echo -e "\n🔄 Синхронизация с Git..."
    cd ~/wheelzone-script-utils || return 1
    if [[ -n $(git status --porcelain) ]]; then
        git add .
        git commit -m "[Test] Результаты тестирования $(date +%Y-%m-%d)"
        git pull --rebase
        git push
    else
        echo "✅ Нет изменений для коммита"
    fi
}

main() {
    echo "🔧 Комплексное тестирование wz_chatend.sh"
    echo "📝 Логи тестирования: $LOG_FILE"
    check_dependencies
    init_test
    local start_time=$(date +%s)
    run_tests
    local test_result=$?
    local end_time=$(date +%s)
    echo -e "\n📊 Итоги тестирования:"
    echo "  - Время выполнения: $((end_time - start_time)) сек"
    echo "  - Обнаружено ошибок: $test_result"
    if [[ $test_result -eq 0 ]]; then
        echo -e "\n🎉 Все тесты пройдены успешно!"
    else
        echo -e "\n❌ Обнаружены проблемы в тестах"
    fi
    git_sync
}

main
