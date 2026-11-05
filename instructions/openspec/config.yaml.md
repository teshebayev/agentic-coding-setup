# Инструкция агенту: `openspec/config.yaml`

- **Что это:** проектная конфигурация OpenSpec: контекст проекта и правила для каждого артефакта
- **Когда подхватывается:** не Claude Code, а OpenSpec CLI: `openspec instructions <артефакт>` подмешивает `context` и `rules` в инструкции, которые читают скиллы `openspec-*`. `operations.*.guidance` — подсказки для apply и archive
- **Действие при переносе:** **переписать** — содержимое про проект «DWH-аналитик», в вашем проекте нужно своё

## Что в файле сейчас (проект «DWH-аналитик»)

- `schema: spec-driven`.
- `context`: язык артефактов (ru, английские SHALL/MUST и заголовки OpenSpec), домен (менеджеры склада, LLM пишет
  SQL…), стек (Python 3.12, uv workspace, FastAPI, Postgres/SQLite, OpenRouter, pytest), ключевые инварианты
  (плагины и слои, event log и replay, DWH через MCP, два профиля, знание через ревью, документация по-русски).
- `rules.proposal`: перенос договорённостей из `/grill-with-docs`; термины из `GLOSSARY.md`; обязательные разделы;
  полный шаблон структуры (Why, What Changes, Goals, Non-Goals, Users & Scenarios, Requirements с NFR-S/RP/C/P,
  Матрица профилей, Success Metrics, Open Questions); «что и зачем, не как».
- `rules.design`, `rules.tasks` (порядок слоёв, ссылки на FR, автотесты, `verify`, обязательная группа
  «Документация», блоки ≤ 2 ч), `rules.specs` (дельта-формат, пометки FR).
- `operations.apply.guidance` (стиль кода, характеризационный тест, pytest после групп, живой DWH с разрешения,
  `replay-reviewer`, без коммитов), `operations.archive.guidance` (документация, предложение коммита).

## Что должно быть в вашем проекте

Та же структура: `context` — ваш язык, домен (кто пользователи, что делает система), стек, 4–7 ключевых
инвариантов (те же, что в Architecture `CLAUDE.md`). `rules.*` — каркас наш, с вашими NFR-категориями, матрицей
окружений, порядком слоёв в tasks, командами тестов, ревьюером.

## Шаги адаптации

1. Сначала `openspec init --tools claude --language <язык>` (создаст свой `config.yaml`), затем замени его нашим и перепиши.
2. `context` — с нуля по фактам о проекте; язык спроси у пользователя.
3. В `rules.proposal` поменяй NFR-категории (синхронно с `traceability.md`), Users & Scenarios (ваши роли),
   матрицу окружений или удали её.
4. В `rules.tasks` — порядок слоёв вашей архитектуры (например «схема БД → домен → API → UI → документация»),
   команды тестов; убери пункт про `harness.cli verify` или замени своим.
5. В `operations.apply.guidance` — ваши команды, условие «только с разрешения», имя ревьюера.
6. Проверка: `openspec validate --help` / `openspec instructions proposal --help` — убедись, что CLI читает
   конфиг без ошибок; лучше всего — пробный `/opsx:propose` на мелкой идее и удаление изменения после.

## Связи с другими файлами

`traceability.md`, `proposal-format.md`, `delta-specs.md`, `design-decisions.md`, `test-planning.md`, `GLOSSARY.md`, `.claude/agents/`, `CLAUDE.md`.
