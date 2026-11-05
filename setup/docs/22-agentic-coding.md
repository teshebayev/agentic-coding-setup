# Агентная разработка: как Claude Code работает с этим репозиторием

Здесь описано, как устроена разработка харнесса вместе с Claude Code: процесс изменений, правила,
хуки, скиллы и MCP. Сетап заимствует идеи [oinsio/clear-progress](https://github.com/oinsio/clear-progress)
и переложен на наш стек: Python и pytest вместо TypeScript и vitest, плюс домен харнесса.

## Установка (один раз на машину)

```bash
uv sync                                   # подтянет ruff (группа dev)
# Node ≥ 20 и OpenSpec CLI; на этой машине Node стоит в ~/.local/opt, ссылки лежат в ~/.local/bin
npm i -g @fission-ai/openspec@1.14.3
openspec config set telemetry.enabled false
uv run python -m harness.cli seed-demo    # демо-DWH для MCP-сервера из .mcp.json
```

Остальное хранится в репозитории: `.claude/` (правила, скиллы, команды, хуки, субагент), `openspec/`,
`.mcp.json`, `scripts/agent/`.

## Процесс изменения

```
неясная идея ── /grill-with-docs ──┐
                                   ├─→ /opsx:propose ─→ /opsx:apply ─→ /opsx:archive ─→ коммит
исследование ── /opsx:explore ─────┘    (та же сессия)   (новая сессия)
```

| Шаг | Что происходит | Где результат |
|---|---|---|
| `/grill-with-docs` | Интервью раундами: на каждый вопрос есть рекомендованный ответ, а факты из кода агент ищет сам. Договорённые термины сразу попадают в глоссарий, редкие трудные решения оформляются как ADR | `GLOSSARY.md`, `docs/adr/` |
| `/opsx:explore` | Свободное исследование без кода: варианты, схемы, разбор устройства кода | разговор |
| `/opsx:propose` | Изменение и его артефакты: proposal с ID требований, дельта-спеки, design (если есть реальный выбор), tasks | `openspec/changes/<имя>/` |
| `/opsx:apply` | Реализация задач по порядку с отметками в tasks.md. Внутри работают TDD, systematic-debugging и verification из superpowers | код и тесты |
| `/opsx:apply-sequential` | То же для больших изменений: каждая задача идёт в свежем субагенте, задачи строго по очереди, без коммитов | код и тесты |
| `/opsx:archive` | Проверяет, что документация обновлена; вливает дельта-спеки в `openspec/specs/`; переносит изменение в архив | `openspec/changes/archive/` |

Тонкие места:

- **grill запускается отдельно**, не изнутри `/opsx:*`. Внутри обёрток скилл молча перестаёт писать файлы.
  Решения, которые не попали ни в глоссарий, ни в ADR, остаются только в разговоре. Поэтому `/opsx:propose`
  нужно запустить в той же сессии: правило в `openspec/config.yaml` заставляет перенести договорённости в proposal.
- **apply — в чистой сессии**. Устаревший контекст порождает несвязный код.
- Для мелочей (опечатка, однострочный баг с тестом) изменение не заводится.
- Superpowers по-прежнему установлен. Для изменений в этом репозитории его brainstorming и writing-plans
  заменяет OpenSpec. `docs/plans/` остаётся архивом прежних планов.

Контекст проекта и правила артефактов лежат в [../openspec/config.yaml](../openspec/config.yaml). Нефункциональные
требования у нас свои: **NFR-S** (безопасность), **NFR-RP** (совместимость replay), **NFR-C** (стоимость и кэш),
**NFR-P** (производительность). Вместо UI-матрицы используется «Матрица профилей»: SQLite/Postgres × demo/live × CLI/API/LibreChat.

## Правила

`.claude/rules/*.md` написаны на русском, полный список — в таблице в [../CLAUDE.md](../CLAUDE.md). Глобальные
правила (процесс, TDD, что можно запускать) загружаются всегда. Остальные загружаются только при работе с
путями из их `paths:`. Например, `event-log.md` (replay, `build_request`, префикс кэша) появляется в контексте,
когда Claude открывает `harness/core/**`. Поэтому CLAUDE.md остаётся коротким, а доменные инварианты не теряются.

## Хуки

Хуки подключены в [../.claude/settings.json](../.claude/settings.json), скрипты лежат в [../scripts/agent/](../scripts/agent/).

| Хук | Скрипт | Что делает |
|---|---|---|
| PreToolUse | `guard.sh` | **Запрещает** чтение `.env`, `ACCESS.local.md`, `DWH-Tunnel-*`, `external/` и их упоминание в командах (`.env.example` разрешён), `docker compose config` без `--quiet`, правку архива изменений. **Спрашивает** перед `-m live`, `eval.run_control`, `marts apply/test/plan/status/cards` и перед `harness.cli ask/chat` без demo-слоя |
| PostToolUse | `post-edit.sh` | Для изменённого `.py` запускает ruff (F, E9). Ищет импорт `dwh_analyst_mcp` из `harness/`. Проверяет, что каждый плагин из `base.yml` есть в `dwh.yml`. Замечания передаёт Claude через `additionalContext`, ничего не блокирует |
| Stop | `stop-tests.sh` | Если `.py` изменились с последнего зелёного прогона, запускает `uv run pytest -q -x` (≈13 с). Красные тесты один раз возвращают Claude к работе |

Если хук мешает в конкретной сессии, его можно отключить через `/hooks` или в `.claude/settings.local.json`
(этот файл не коммитится). Скрипты проверяются подачей JSON на stdin, например:
`echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' | scripts/agent/guard.sh`.

## Скиллы, команды, субагенты

| Что | Зачем |
|---|---|
| `harness-plugin` | Чек-лист нового плагина: оба слоя конфига, события вместо состояния, тест, README/STATUS |
| `dwh-playbook` | Плейбук: черновик держать вне `playbooks/`, сверить `tests.yml`, живой DWH только с разрешения |
| `alembic-migration` | Ручная миграция под SQLite и Postgres с тестом |
| `split-large-tests` | Разбить большой файл тестов, не потеряв ни одного теста |
| `replay-reviewer` (субагент) | Ревью диффа на детерминизм replay и совместимость payload; его вызывает `/opsx:apply` |
| `/uncommitted-files`, `/fix-uncommitted` | Чек-лист незакоммиченных файлов и их разбор по одному субагенту на файл (диагностика VS Code, ruff, дубли) |
| `/refactor-claude-md` | Аудит CLAUDE.md: что удалить, а что перенести в правила, скиллы или хуки |

Откуда взяты скиллы и можно ли их править, описано в [../.claude/skills/README.md](../.claude/skills/README.md).
Сгенерированные `openspec-*` и `/opsx:*` обновляются командой `openspec update`, руками их не правят.

## MCP

[../.mcp.json](../.mcp.json) подключает MCP-сервер `dwh-analyst` в **demo**-профиле: SQLite и демо-знание.
Через него Claude Code вызывает `search_schema`, `validate_sql` и `get_playbook`, пока пишет плейбуки и
валидатор. Профиль живого DWH в коммит не попадает. Если он нужен, его описывают локально в
`.claude/settings.local.json` и подключают только с разрешения.

## Что взято из clear-progress и что изменено

| В clear-progress | У нас |
|---|---|
| OpenSpec, `/opsx:*` | То же, OpenSpec 1.14.3. Артефакты на русском, свои правила в `config.yaml`, архив без группировки по `YYYY/MM` |
| 22 правила (UI, i18n, BDD, Temporal, hardcoded) | 17 правил под наш домен. UI, i18n, BDD и мутационное тестирование не берём (последнее — кандидат в TODO) |
| Хуки: check-hardcoded, весь vitest и lint:fix после **каждой** правки | ruff и проверки слоёв после правки, тесты один раз на остановке с кэшем зелёного прогона. Предупреждения идут через `additionalContext`: обычный stdout PostToolUse Claude не видит |
| `get_file_problems` из JetBrains MCP | `mcp__claude-vscode__getDiagnostics` и ruff |
| — | Охрана секретов и живого DWH (`guard.sh`), `/grill-with-docs`, доменные скиллы, `replay-reviewer` |

Файлы clear-progress выпущены под PolyForm Noncommercial, поэтому мы их **не копируем**: текст правил, команд и
скриптов написан заново. Из внешних источников вендорятся только MIT-материалы: сгенерированный OpenSpec и
скиллы `grill-with-docs`, `grilling`, `domain-modeling` из [mattpocock/skills](https://github.com/mattpocock/skills).
