# WheelZone Script Utils

Этот репозиторий содержит все исполняемые скрипты, конфигурации и утилиты проекта **WheelZone**:

- 🧠 Bash/Python/YAML скрипты
- 📱 Android/Termux интеграции (mobile/)
- 🧩 Bash CLI-интерфейсы (cli/)
- 🕒 Планировщики (cron/)
- 🧪 Тесты (tests/)
- 📡 Мониторинг (monitoring/)
- ⚙️ Конфигурации среды (configs/)
- 📦 CI/CD, установщики, шаблоны (templates/, install.sh)

🧠 Документация, правила, отчёты и архитектура хранятся в отдельном репозитории:

👉 https://github.com/skladkoles44/wz-wiki

## wz_ai_autolog.sh
Логгирование команд в NDJSON для последующего анализа. Используется в CRON, CI, и внутри WZ-ботов.

Примеры:
- `wz_ai_autolog.sh "mem" free -h`
- `wz_ai_autolog.sh "uptime" uptime`

> См. `examples/wz_ai_autolog_demo.sh` и `configs/wz_ai_autolog.cronrc`
