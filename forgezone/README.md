# ForgeZone — AI Forge for Code

> Где один ИИ пишет, второй оттачивает, третий критикует.

---

## 🛠️ Компоненты

- `forge_pipeline.yaml` — описание последовательности агентов
- `agent_profiles/` — конфигурации агентов (Initiator, Refiner и т.д.)
- `forge_runner.py` — запуск входного файла через pipeline
- `test_cases/` — входные скрипты и идеи
- `forge_results/` — результаты работы (файлы, отчёты)
- `forge_memory/` — архив входных данных

---

## 🚀 Пример использования

```bash
./forge_runner.py --input test_cases/script1.sh --agent-pipeline default_refinement


---

🌱 В планах

Поддержка GPT-4.5, suicide_critic, shellcheck, pylint

DIFF и hash между версиями

Регистрация в ChatEnd и Git EOF
