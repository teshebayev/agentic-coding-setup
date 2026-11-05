---
paths:
  - "harness/core/**"
  - "harness/context/**"
  - "harness/llm/**"
  - "harness/tools/pipeline.py"
---

# Правило: лог событий и детерминированный replay

Подробно — `harness/core/README.md`, `harness/context/README.md`.

- **Единственная запись** — `SessionLog.append()` (валидация payload, маскирование секретов). Лог только
  дописывается; триггеры в базе запрещают `UPDATE`/`DELETE` в `events`.
- **История модели не хранится.** Её каждый шаг строит `derive_messages(events)` — единственный способ.
- **`build_request()` — чистая функция** от (config, events, mode). `step/start` пишет `request_hash`;
  `harness.cli verify <сессия>` пересобирает запросы и сравнивает хэши.
- Всё, что видит модель, должно прийти из событий (`context/injected` с `source=…`, `tool/result`, …), а не
  из полей объектов, глобалей, текущего времени или файлов, прочитанных при сборке.
- **Старые логи воспроизводятся.** Новое поле payload — необязательное, со значением по умолчанию; смысл
  старого поля не меняется. Переименование типа события — только с чтением старого имени.
- **Префикс кэша.** Стабильные секции (`role`, `conventions`, `schema_index`, `playbook_index`) идут до
  летучих (`task_state`); правка стабильной секции сбрасывает кэш у всех сессий — это NFR-C в proposal.

После правки здесь: `uv run pytest -q`, затем `harness.cli verify` по демо-сессии и субагент `replay-reviewer`.
