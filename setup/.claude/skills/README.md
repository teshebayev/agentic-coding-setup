# Скиллы Claude Code в этом репозитории

Откуда взялись и можно ли править. Процесс целиком — `docs/22-agentic-coding.md`.

| Скилл | Источник | Править? |
|---|---|---|
| `openspec-*` | генерирует `openspec init`/`openspec update` (OpenSpec 1.14.3, MIT) | нет — перезапишется; своё — в `openspec/config.yaml` |
| `grill-with-docs`, `grilling`, `domain-modeling` | [mattpocock/skills](https://github.com/mattpocock/skills) @ `59db609`, MIT (`LICENSE-mattpocock-skills`) | нет — обновлять заменой файлов с новым коммитом; адаптация — в `.claude/rules/glossary.md`, `adr.md` |
| `harness-plugin`, `dwh-playbook`, `alembic-migration`, `split-large-tests` | свои | да |

`grill-with-docs` — однострочный делегат: без `grilling` и `domain-modeling` он не работает, удалять их по отдельности нельзя.
