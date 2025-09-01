---
fractal_uuid: 39661f3c-5170-43ba-870e-37e884dde398
---
# check_gdrive.sh — аудит rclone remote (Google Drive и аналоги)

## Быстро посмотреть руками
```bash
~/wheelzone-script-utils/scripts/utils/check_gdrive.sh

Машинно для ботов/CI (JSON)

~/wheelzone-script-utils/scripts/utils/check_gdrive.sh --json > /tmp/gd_status.json
jq .status /tmp/gd_status.json 2>/dev/null || cat /tmp/gd_status.json

YAML (для YAML-ориентированных отчётов)

~/wheelzone-script-utils/scripts/utils/check_gdrive.sh --yaml > /tmp/gd_status.yaml

С кастомными порогами

~/wheelzone-script-utils/scripts/utils/check_gdrive.sh --json --warn-days 3 --min-free-gb 2


---

Коды возврата

0 — всё норм

20 — предупреждение (мало места или токен скоро истечёт)

10/11/12/13 — фатальные проблемы (rclone/remote/about/lsd)



---

