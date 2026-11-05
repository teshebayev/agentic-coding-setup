# Агентный сетап Claude Code: правила, хуки, скиллы, OpenSpec

Сетап для разработки вместе с Claude Code, снятый с рабочего проекта «DWH-аналитик» (Python-харнесс над
хранилищем данных) 31.10.2026. Внутри — файлы как они есть в том проекте и к каждому файлу инструкция для агента:
что это, что в нём сейчас и что должно быть в вашем проекте. Перенос и адаптацию делает сам Claude Code.

## Что даёт сетап

- **Процесс изменений** на OpenSpec: `/grill-with-docs` (интервью + глоссарий и ADR) → `/opsx:propose`
  (proposal с ID требований, дельта-спеки, design, tasks) → `/opsx:apply` или `/opsx:apply-sequential` →
  `/opsx:archive`. Требования трассируются до кода и тестов.
- **Правила** в `.claude/rules/`: глобальные грузятся всегда, доменные — только когда агент трогает свою область
  кода (`paths:`). `CLAUDE.md` остаётся коротким.
- **Хуки** (`scripts/agent/`): проверка сетапа на старте, запрет читать секреты и запускать опасное (сбой хука блокирует
  вызов), «спросить» перед дорогими командами, линтер после каждой правки, тесты при остановке агента (с кэшем прогона).
- **Скиллы и команды**: процедуры проекта, разбор незакоммиченных файлов по субагенту на файл, аудит `CLAUDE.md`,
  субагент-ревьюер одного класса ошибок.

## Что внутри

```
agentic-coding-setup/
├── README.md            ← этот файл (для человека)
├── ADAPT.md             ← задание агенту: порядок переноса, вопросы, проверки
├── setup/               ← файлы сетапа в путях от корня репозитория (со скрытыми папками)
│   ├── CLAUDE.md  GLOSSARY.md  .mcp.json  .gitignore
│   ├── .claude/         settings.json, settings.local.json, rules/ (17), skills/ (13), commands/ (10), agents/ (1)
│   ├── .superpowers/    sdd/.gitignore
│   ├── scripts/agent/   doctor.sh, guard.sh, post-edit.sh, stop-tests.sh, uncommitted-files.sh, check_plugin_layers.py
│   ├── openspec/        config.yaml, specs/, changes/archive/
│   └── docs/            22-agentic-coding.md (описание сетапа), adr/0001-… (пример ADR)
├── instructions/        ← та же структура: instructions/<путь>.md на каждый файл из setup/
└── examples/            ← образец завершённого изменения OpenSpec (proposal, specs, design, tasks)
```

Скрытые папки в архиве есть: в файловом менеджере включите показ скрытых файлов (`ls -la`).

## Что нужно на машине

- Claude Code ≥ 2.1.295 (раньше не работает `onFailure: block`); плагин **superpowers** (ставится на уровне пользователя через `/plugin`) — его TDD,
  systematic-debugging и verification работают внутри `/opsx:apply`.
- Node ≥ 20 и OpenSpec CLI 1.14.3: `npm i -g @fission-ai/openspec@1.14.3`.
- `bash`, `jq`, `git`, `sha1sum`, `timeout` — для хуков (на macOS `brew install jq coreutils`). Windows — через WSL
  или Git Bash, иначе скрипты хуков придётся переписать.

## Как поставить в свой проект

1. Распакуйте архив **рядом** с репозиторием или во временную папку — не поверх репозитория.
2. Откройте Claude Code в корне своего репозитория и напишите:

   > Прочитай `<путь-к-архиву>/agentic-coding-setup/ADAPT.md` и перенеси сетап в этот репозиторий по нему.

3. Агент проведёт разведку, задаст один раунд вопросов (язык, что опасно запускать, главные инварианты, хрупкие
   области), перенесёт и адаптирует файлы, прогонит проверки и выдаст отчёт.
4. Перезапустите Claude Code, проверьте `/hooks` и список команд по `/`, закоммитьте.

Переносить руками тоже можно: идите по таблице из `ADAPT.md` (шаг 3) и читайте инструкцию к каждому файлу.

## Что из этого общее, а что придётся заменить

| Общее, переносится почти как есть | Подстраивается под стек | Про чужой домен, заменяется своим |
|---|---|---|
| вендоренные скиллы grill/domain-modeling, команды `/uncommitted-files`, `/refactor-claude-md`, `uncommitted-files.sh`, правила артефактов OpenSpec | хуки, глобальные правила (TDD, тесты, что можно запускать), `/fix-uncommitted`, `/opsx:apply-sequential`, `openspec/config.yaml` | `CLAUDE.md`, 5 доменных правил, 3 доменных скилла, субагент `replay-reviewer`, `.mcp.json`, `GLOSSARY.md`, ADR |

## Лицензии

- Файлы `openspec-*` и `/opsx:*` генерирует OpenSpec (MIT); в своём репозитории получите их через `openspec init`.
- `grill-with-docs`, `grilling`, `domain-modeling` — из [mattpocock/skills](https://github.com/mattpocock/skills)
  @ `59db609`, MIT, лицензия в `setup/.claude/skills/LICENSE-mattpocock-skills`.
- Остальное написано для проекта «DWH-аналитик». Идеи процесса заимствованы у
  [oinsio/clear-progress](https://github.com/oinsio/clear-progress) (PolyForm Noncommercial) — его файлы **не
  копировались**, текст написан заново.
