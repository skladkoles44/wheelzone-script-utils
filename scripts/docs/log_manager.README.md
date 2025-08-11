# 🧾 log_manager.sh — WheelZone Log Manager v2.0

Скрипт управляет логами в системе WheelZone: архивирует их, удаляет старые, синхронизирует с git и блокирует параллельные запуски.

---

## 🚀 Возможности

- 📦 Архивация логов (`*.ndjson`) с отметкой времени
- 🧹 Удаление логов старше 7 дней
- 🔐 Блокировка выполнения через lock-файл
- 🧠 Git-синхронизация (если доступна)
- ✅ Полная поддержка **Termux / Android 15**
- 🔁 Подходит для запуска из `cron`, `watchdog`, `CLI`

---

## 🔧 Переменные окружения

| Переменная      | Назначение                        | Пример                                   |
|----------------|----------------------------------|-------------------------------------------|
| `LOG_SOURCE`    | Папка с исходными логами         | `~/logs/notion`                          |
| `LOG_DEST`      | Папка для архивов                | `~/.wz_logs/archive`                     |
| `SYNC_LOG`      | Файл для лога скрипта            | `~/.wz_logs/sync.log`                    |
| `LOCK_FILE`     | Файл блокировки                  | `~/.wz_logs/.lock`                       |

---

## 🧪 Тесты

Файл: `scripts/tests/test_log_manager.sh`  
Проверяет все функции лог-менеджера: архив, блокировку, очистку.

---

## 📜 Пример использования

```bash
export LOG_SOURCE="$HOME/logs/notion"
export LOG_DEST="$HOME/.wz_logs/archive"
export SYNC_LOG="$HOME/.wz_logs/sync.log"
export LOCK_FILE="$HOME/.wz_logs/.lock"

bash scripts/log_manager.sh


---

📁 Статус

Версия: 2.0

Поддержка: Termux, Linux

Разработано: wheelzone-core EOF
