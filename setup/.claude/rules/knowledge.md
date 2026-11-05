---
paths:
  - "dwh-knowledge/**"
  - "dwh-analyst-mcp/demo/knowledge/**"
  - "harness/memory/**"
---

# Правило: курируемое знание

Подробно — `dwh-knowledge/schemas/README.md`, `dwh-knowledge/playbooks/README.md`, `dwh-knowledge/STATUS.md`;
чек-лист плейбука — скилл `dwh-playbook`.

- `conventions.md`, `traps.md` в корне читаются индексом целиком и идут в стабильный префикс промпта —
  каждая строка стоит токенов в каждом ходе (NFR-C) и сбрасывает кэш.
- Карточки — `schemas/<домен>/*.md` с фронтматтером `kind: table|domain`. Карточки с `source: onec.build`
  генерируются (`python -m dwh_analyst_mcp.onec.build`, полная команда — в `STATUS.md`); правь источник или
  `_domain.md`, а не сгенерированный файл. Ручные карточки генератор не перезаписывает.
- Плейбук — `playbooks/<имя>/`: `SKILL.md` → `*.sql.j2` → `tests.yml`. Папка с `SKILL.md` сразу видна
  модели — черновики держи вне `playbooks/` (например, в `openspec/changes/<change>/`).
- Версия знания — хэш содержимого: любая правка меняет её у всех проверенных примеров.
- Демо-набор `dwh-analyst-mcp/demo/knowledge/` — отдельный; тесты и offline-демо зависят от него.
- Источники генератора: Notion-экспорт в `dwh_description/` и граф метаданных 1С в `onec/wms/`.

## Цикл знания (`harness/memory/README.md`)

Харнесс-агент в `dwh-knowledge/` **не пишет**. `MemoryExtractorPlugin` (`turn_stopping`) складывает факты
удачных ходов в очередь кандидатов → аналитик принимает или отклоняет (`harness.cli candidates …`,
`/admin/candidates`) → принятый пишет changeset в `dwh-knowledge-inbox/` (gitignored) → аналитик переносит
руками. Проверенные пары «вопрос → SQL» (`harness.cli verified …`) возвращаются примерами через
`VerifiedExamplesPlugin`. Оценка менеджера (`feedback`, `/верно`/`/неверно`) **не** делает пару доверенной,
пока не включён `trust_on_feedback: true`. Обзор ходов для аналитика — `harness.cli turns-report`.
