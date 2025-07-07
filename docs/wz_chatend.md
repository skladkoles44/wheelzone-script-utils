# 📘 Скрипт `wz_chatend.sh`

> Версия: **2.4**  
> Расположение: `scripts/wz_chatend.sh`  
> Назначение: Генерация итогового отчёта завершённого чата ChatEnd (Markdown + YAML)

---

## 🧭 Назначение

Скрипт `wz_chatend.sh` используется для:
- финализации переписки с GPT;
- генерации отчёта в формате Markdown (`.md`);
- создания YAML-заголовка с UUID, slug, датой и хэшем;
- размещения отчёта в `~/wz-knowledge/WZChatEnds/`.

---

## 🛠 Структура и логика

### Этапы работы:
1. Проверка файла с инсайтами (`tmp_insights.txt`)
2. Генерация имени `chat_YYYY-MM-DD_slug.md`
3. Копирование содержимого инсайтов
4. Генерация:
   - SHA256 хэша
   - UUID (на основе содержимого)
   - YAML-заголовка
5. Сохранение в `$OUTPUT_DIR`

### YAML-заголовок отчёта:
```yaml
---
uuid: <uuid5>
slug: <slug>
filename: "chat_2025-07-07_slug.md"
date: "2025-07-07"
sha256: "<sha256>"
generator: wz_chatend.sh v2.4
format: markdown+yaml
---


---

⚙️ Переменные окружения

Переменная	Назначение	Значение по умолчанию

INSIGHTS_FILE	Путь до файла tmp_insights.txt	$HOME/wzbuffer/tmp_insights.txt
OUTPUT_DIR	Каталог сохранения итогового .md отчёта	$HOME/wz-knowledge/WZChatEnds



---

🔗 Связки и взаимодействие

📌 Взаимодействует с:

wz_block_parser.sh — заполняет tmp_insights.txt

chatlog, end_blocks.txt — источники для блока INSIGHT, TODO, DONE

wz_chatend_helpers.sh — может использоваться для вспомогательных функций (в будущем)

wzdrone_chatend.sh (CI) — запускает wz_chatend.sh автоматически при push

notion_log_entry.py — логирует отчёт в базу Notion ChatEnd Summaries (если подключено)


📂 Git-связи:

Создаваемые .md файлы — отслеживаются в wz-wiki/WZChatEnds/

Пуш осуществляется вручную или через CI (WZDrone)


📤 Автофиксация rclone.conf

Если в системе найден ~/.config/rclone/rclone.conf, создаётся YAML-запись с:

названием удалённого ([remote])

временем окончания токена (expiry)

статусом completed



---

▶️ Пример использования

end

Или вручную:

INSIGHTS_FILE=~/wzbuffer/tmp_insights.txt \
OUTPUT_DIR=~/wz-knowledge/WZChatEnds \
bash ~/wheelzone-script-utils/scripts/wz_chatend.sh


---

📦 Вывод

Успешный результат:

[+] ChatEnd отчёт сохранён: /data/data/com.termux/files/home/wz-knowledge/WZChatEnds/chat_2025-07-07_slug.md


---

✅ Статус

Готов к CI и интеграции с Notion

Версия: v2.4

Поддерживает: Termux, Android, bash



---

💡 Рекомендации

В будущем вынести YAML-заголовок в отдельный .yaml файл

Добавить логирование и поддержку --help, --version

Интегрировать check_yaml и validate_chatend_format


