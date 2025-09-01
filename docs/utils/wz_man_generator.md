---
fractal_uuid: f1b95cd7-9fd9-40eb-9688-ffbe8a72ece0
---
# WZ man generator — автосборка man-страниц из аннотаций

Скрипты в `scripts/utils/*.sh` и `cli/*.sh` могут содержать строки `# man:`:
```bash
# man: name=tool_name
# man: section=1
# man: version=1.0
# man: date=2025-08-27
# man: author=WheelZone Automation Stack
# man: synopsis=tool_name [--flags]
# man: description=Short description here.
# man: options=--flag  explanation
# man: exit=0  ok
