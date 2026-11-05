---
paths:
  - "harness/storage/**"
  - "alembic.ini"
---

# Правило: хранилище и миграции

Подробно — `harness/storage/README.md`; чек-лист — скилл `alembic-migration`.

- Два профиля на одних протоколах (`SessionStore`, `ArtifactStore`, `ObjectStore`): SQLite + файлы (демо,
  тесты, архив пилота) и Postgres + MinIO (по умолчанию). Любая правка работает в обоих.
- Миграции — **руками** в `harness/storage/migrations/versions/NNNN_*.py`: без SQLAlchemy-моделей и
  autogenerate; `op.execute`/`op.create_table` с ветками по диалекту, где синтаксис расходится. Рантайм —
  sqlite3/psycopg напрямую.
- Ревизия не ломает уже накатанные базы; удалять и переименовывать колонки с данными пилота — только через
  ADR и согласование.
- `auto_migrate` включён на хосте и выключен в docker (там контейнер `migrate`).
- Тесты: офлайн — SQLite; Postgres-интеграция — `tests/test_postgres_storage.py` при заданных `HARNESS_PG_*`.
