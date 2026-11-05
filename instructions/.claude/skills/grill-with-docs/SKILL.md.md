# Инструкция агенту: `.claude/skills/grill-with-docs/SKILL.md`

- **Что это:** скилл `/grill-with-docs`: интервью по плану с одновременной записью глоссария и ADR
- **Когда подхватывается:** только вручную (`disable-model-invocation: true`) — пользователь пишет `/grill-with-docs`
- **Действие при переносе:** **не править** — сторонний MIT-скилл, обновляется заменой файлов

## Что в файле сейчас (проект «DWH-аналитик»)

Однострочный делегат: «вызови скиллы `grilling` и `domain-modeling`». В нашем процессе запускается отдельно (не изнутри `/opsx:*`), а `/opsx:propose` — в той же сессии, чтобы перенести договорённости.

## Что должно быть в вашем проекте

Тот же файл.

## Шаги адаптации

1. Скопируй без изменений (скилл общий, проектная адаптация — в `.claude/rules/glossary.md` и `adr.md`).
2. Обновление — заменой файлов из нового коммита https://github.com/mattpocock/skills; поправь коммит в
   `.claude/skills/README.md`.
3. Три скилла `grill-with-docs`, `grilling`, `domain-modeling` переносятся только вместе.

## Связи с другими файлами

`grilling`, `domain-modeling`, `openspec/config.yaml` (первое правило rules.proposal), `CLAUDE.md` (Workflow).
