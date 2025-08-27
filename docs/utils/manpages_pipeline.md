# Manpages pipeline (CI + VPS)

## Локально
- `~/wheelzone-script-utils/cli/wz-docs-refresh` — генерировать+установить man в Termux
- `~/wheelzone-script-utils/cli/wz-multipull` — multipull + обновить man
- `~/wheelzone-script-utils/scripts/ci/wz_build_manpages.sh` — собрать tar.gz + sha256 + INDEX.md
- `~/wheelzone-script-utils/cli/wz-pub-wiki` — синхронизировать .1 + artifacts в wz-wiki
- `~/wheelzone-script-utils/cli/wz-pub-vps` — выгрузить artifacts на VPS
- `~/wheelzone-script-utils/cli/wz-pub-nginx` — установить/обновить nginx-сайт на VPS

## Drone CI
- `.drone.yml` — собирает артефакты, пушит их в репозиторий, опционально публикует на VPS.
- Секреты: `GIT_SSH_KEY`, `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `VPS_HOST`, `VPS_PORT`, `VPS_DEST`.

## Nginx на VPS
- Конфиг: `/etc/nginx/sites-available/wz-manpages.conf`
- Каталог: `/var/www/wz-manpages`
- Autoindex включён, gzip включён, .sha256 отдаются как text/plain.

