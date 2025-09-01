---
fractal_uuid: 9bb4eb5c-bb61-4caa-b6d3-e8a09b4d8599
---
# Автообновление man-страниц через Git hooks

## Что делает
- `post-merge`, `post-checkout`, `post-rewrite` запускают генератор и установщик:
  - `scripts/utils/wz_gen_manpages.sh`
  - `scripts/utils/wz_install_manpages.sh`
- Каталог хуков: `.githooks/` (треком в Git).
- Включено `core.hooksPath=.githooks`.

## Быстрые команды
```bash
wzpull   # git pull текущей ветки + генерация + установка man
wzdocs   # только генерация + установка man
gap      # add+commit+push (gap "$REPO" "message")

Примечания

Если пакета man нет в Termux — установи: pkg install man

Хуки безопасно игнорируют отсутствие утилит: скрипты молча пропускаются. MD
