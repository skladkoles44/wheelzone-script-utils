# UUID Enforcer (fractal_uuid)

## Что делает
- Добавляет `fractal_uuid` в начало `.md/.yml/.yaml/.1`.
  - Markdown: YAML front matter `--- fractal_uuid: <uuid> ---`.
  - Roff (`.1`): строка-комментарий `.\" fractal_uuid: <uuid>`.
- Для бинарей (`*.tar.gz`, `*.sha256`) создаёт `*.meta.yaml` с uuid, временем, sha256.

## Использование
```bash
~/wheelzone-script-utils/cli/wz-uuid-fix      # быстро поправить всё
~/wheelzone-script-utils/scripts/utils/wz_uuid_enforcer.sh "$HOME/wheelzone-script-utils" check

Автоматизация

pre-commit хук запускает фикс перед каждым коммитом.

Билдер артефактов добавляет sidecar автоматически. MD

MD
