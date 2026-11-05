---
paths:
  - "dwh-analyst-mcp/**"
  - "harness/tools/mcp_client.py"
  - "harness/tools/sql_guard.py"
  - "harness/tools/checks.py"
---

# Правило: граница MCP

Подробно — `dwh-analyst-mcp/README.md`, `harness/tools/README.md`.

- DWH доступен только через MCP-сервер `dwh-analyst-mcp` (отдельный процесс, stdio, запускает
  `harness/tools/mcp_client.py`). `harness/` **не импортирует** `dwh_analyst_mcp` — хук предупредит.
- Сервер: `search_schema`/`get_schema`, плейбуки, `validate_sql`, `run_sql`, граф метаданных 1С; только
  чтение.
- `SqlGuardPlugin` перед `run_sql` сам зовёт `validate_sql` и отказывает при замечаниях; повтор того же SQL
  за ход — `budget:repeated_sql`. `AnswerCheckPlugin` отклоняет ответ, если числа не из `run_sql` или
  `reconcile_stock`, или период не совпадает с границами `task_state`. Ослабление этих проверок — только
  через proposal с NFR-S.
- Скоуп данных пользователя передаётся в `_meta` вызова и проверяется на сервере; ПДн-колонки закрыты
  валидатором.
- Большие результаты — артефакты; модель видит превью.
- Тесты сервера — `dwh-analyst-mcp/tests/`, на демо-знании `dwh-analyst-mcp/demo/knowledge/`.
