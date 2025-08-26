#!/data/data/com.termux/files/usr/bin/bash
# uuid: 2025-08-26T13:20:16+03:00-1840674032
# title: test_suite_wheelzone.sh
# component: .
# updated_at: 2025-08-26T13:20:16+03:00

# Авто-стресс-тест системы WheelZone
# Дата генерации: 2025-05-08 13:05:32

echo "[StressTest] Начат системный стресс-тест"

# Шаг 1: Создание ценного файла
echo '{}' > ~/storage/downloads/test_valuable.json
echo "[StressTest] Создан ценный файл test_valuable.json"

# Шаг 2: Удаление вручную (эмуляция)
rm -f ~/storage/downloads/test_valuable.json
echo "[StressTest] Файл удалён вручную"

# Шаг 3: Создание большого файла
fallocate -l 60M ~/storage/downloads/big_test.iso
echo "[StressTest] Создан тяжёлый файл big_test.iso (60 МБ)"

# Шаг 4: Проверка подмены BackUp пути
touch ~/wheelzone/BackUp/test.txt
echo "[StressTest] Создан тестовый файл с путём BackUp"

# Шаг 5: Эмуляция зависшего git pull
touch ~/wheelzone/bootstrap_tool/.git/index.lock
echo "[StressTest] Создан .git/index.lock для проверки автоустранения"

# Шаг 6: Подкидываем файлы в temp
mkdir -p ~/temp
touch ~/temp/install.sh ~/temp/config.ini ~/temp/debug.log
echo "[StressTest] Подкинуты файлы в папку temp"

# Шаг 7: Прослушка запуска
echo "[StressTest] Эмуляция запуска Termux с прослушкой (отображение ошибок будет при следующем старте)"

echo "[StressTest] Стресс-тест завершён"
