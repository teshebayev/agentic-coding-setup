---
name: harness-plugin
description: Чек-лист нового плагина харнесса или нового хука в существующем — register(ctx), приоритет хука, оба слоя конфига, события вместо состояния, тест, README/STATUS. Используй, когда добавляешь или подключаешь плагин в harness/, вешаешь хук pre_step/pre_tool/post_tool/post_step/stop_check/turn_stopping, добавляешь секцию промпта или инструмент.
---

# Новый плагин харнесса

Правила области — `.claude/rules/plugins.md`, `.claude/rules/event-log.md`. Карта хуков и приоритетов —
`harness/README.md`; образец небольшого плагина — `harness/context/cache_monitor.py`.

## Шаги

1. **Найди похожий плагин** и повтори его форму: класс с `name`, `__init__(**options)` (опции из конфига),
   `register(self, ctx)` — `ctx.hooks.on("<хук>", fn, priority=N, name=...)`, секции через `ctx.prompt`,
   инструменты через `ctx.tools`, сервисы в `ctx.services[...]`.
2. **Приоритет.** Посмотри в `harness/README.md`, кто уже висит на этом хуке, и выбери число так, чтобы
   порядок был осмысленным. Запиши приоритет в README модуля.
3. **Всё, что увидит модель, — через событие** (`context/injected` с `source=…` и т.п.), а не через
   состояние плагина. Сборка запроса должна остаться чистой функцией лога.
4. **Сбой не роняет ход**, если плагин необязательный: лови исключение, пиши `log.warning`, продолжай.
5. **Конфиг.** Строка `module:Class` (или `{path, options}`) в `plugins:` **и `base.yml`, и `dwh.yml`**
   (порядок важен — это порядок регистрации). Настройки — в своём разделе `base.yml` с безопасным значением по
   умолчанию; секреты — `${VAR:-}`. Хук `post-edit` проверит, что `base.yml ⊆ dwh.yml`.
6. **Тест** (TDD, `.claude/rules/tdd-workflow.md`): офлайн на SQLite и сценарной модели — по образцу
   соседних тестов в `tests/` (фикстуры в `tests/conftest.py`).
7. **Replay.** Затронута сборка запроса или события → `harness.cli verify` по демо-сессии и субагент
   `replay-reviewer`.
8. **Документация:** строка в таблице `harness/README.md`, README.md и STATUS.md модуля.

## Готово, когда

- `uv run pytest -q` зелёный, `uv run ruff check .` чистый;
- плагин есть в обоих слоях, offline-демо (`--layers base.yml,dwh.yml,demo.yml ask …`) отвечает;
- README/STATUS обновлены.
