---
paths:
  - "openspec/changes/**/specs/**"
  - "openspec/specs/**"
---

# Правило: дельта-спеки

Во время работы спека лежит в `openspec/changes/<change>/specs/<capability>/spec.md` и описывает только
разницу; после `/opsx:archive` она вливается в `openspec/specs/<capability>/spec.md`.

- Маркеры ADDED / MODIFIED / REMOVED; одна возможность (capability) — один файл.
- Каждое требование и сценарий помечены `# реализует FRn из <change>`.
- Сценарий — дано / когда / тогда в терминах поведения харнесса, не реализации:
  «когда модель вызывает run_sql без validate_sql — тогда вызов отклоняется с ошибкой guard», а не «в
  `sql_guard.py` проверяется флаг».
- Имена capability — по смыслу (`sql-guard`, `answer-check`, `report-schedule`), не по файлам.
- `openspec/specs/` не правим руками и не наполняем задним числом — только через архив изменений.
