---
paths:
  - "docs/**"
  - "**/README.md"
  - "**/STATUS.md"
  - "TODO.md"
  - "PATTERNS.md"
  - "dwh-analyst-harness-architecture.md"
---

# Правило: документация

Всё по-русски.

| Документ | Что это |
|---|---|
| `dwh-analyst-harness-architecture.md` | целевая спека (как должно быть), не описание кода |
| `docs/NN-*.md` | код как есть, сценарии; новый файл — следующий номер, ссылка в `docs/README.md` |
| `<модуль>/README.md` | как модуль работает: файлы, классы, хуки и приоритеты |
| `<модуль>/STATUS.md` | сделано / осталось с датами |
| `TODO.md` | индекс отложенного из STATUS-файлов, не второй источник истины |
| `PATTERNS.md` | механизмы, заимствованные у Claude Code |
| `guide.md` | знание аналитика о DWH |
| `openspec/specs/` | поведенческие спеки, растут из архива изменений |
| `docs/adr/` | долгоживущие решения (`.claude/rules/adr.md`) |
| `GLOSSARY.md` | словарь разработки (`.claude/rules/glossary.md`) |

Не цитировать в коммитах содержимое `ACCESS.local.md`, `DWH-Tunnel-*`, `data/`, `external/`, `.env`.
