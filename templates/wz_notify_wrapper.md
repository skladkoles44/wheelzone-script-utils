# wz_notify.sh — Dual Backend CLI for Event Logging

Универсальная обёртка для логгирования событий в системе WheelZone.  
Поддерживает два движка:  
- `wz_notify.py` (v2.4) — расширенный логгер с тегами, типами и шаблонами  
- `wz_notify_atomic.py` (v3.0) — минималистичная реализация с нулевой нагрузкой

## Использование

```bash
# Режим legacy
./wz_notify.sh --title "Сборка завершена" --status SUCCESS

# Режим atomic (скорость >50000 событий/с)
./wz_notify.sh --atomic --title "Event core" --status INFO

Преимущества

Поддержка как функционального, так и предельно оптимизированного логгирования

Совместимость с CI/CD, Termux, FastAPI и IoT-датчиками
