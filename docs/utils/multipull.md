---
fractal_uuid: 1f0a388a-bad3-4ba6-aa09-9c17214cf9ad
---
# wz-multipull — мульти-pull всех репозиториев + обновление man-страниц

## Конфиг
`configs/repos.list` — по одному абсолютному пути к репозиторию на строку.

## Запуск
```bash
~/wheelzone-script-utils/cli/wz-multipull

Сценарий делает git pull --rebase --autostash и затем пытается обновить man-страницы через cli/wz-docs-refresh (если есть), либо напрямую wz_gen_manpages.sh/wz_install_manpages.sh. MD

cat > "$REPO/docs/utils/manpages_ci.md" <<'MD'

CI артефакт manpages (tar.gz)

Скрипт scripts/ci/wz_build_manpages.sh:

генерирует docs/man/*.1,

собирает архив docs/artifacts/manpages-<UTC>.tar.gz,

обновляет docs/artifacts/INDEX.md,

в CI при наличии прав — коммитит и пушит артефакт.


Локально

~/wheelzone-script-utils/scripts/ci/wz_build_manpages.sh

В Drone CI (фрагмент)

Смотри .drone.yml ниже.
