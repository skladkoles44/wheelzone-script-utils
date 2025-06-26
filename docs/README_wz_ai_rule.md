# wz_ai_rule.sh — AI-интерфейс генерации правил для WheelZone

Автоматически формирует технические правила на основе текста, используя OpenRouter (без API-ключа). Поддерживает авто-выбор модели, кеширование, CI, интеграцию с Rule System.

## Использование

```bash
wz rule "Все действия должны логироваться"
wz rule --model anthropic/claude-3-sonnet "Формулируй чётко"
wz rule --dry-run "Без создания файла"
wz rule log

Модели по умолчанию

Claude 3 Sonnet / Opus — для строгих правил

Mistral — быстрые черновики

Cohere — fallback


Файлы

rules/ — Markdown-файлы правил

registry.yaml — YAML-реестр

tmp/wz_ai_cache/ — кеш

tmp/wz_ai_rule.log — лог запросов


MIT, приватный проект WheelZone.
