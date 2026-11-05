---
name: alembic-migration
description: Новая миграция схемы операционного хранилища харнесса — ручная ревизия alembic NNNN_*.py для SQLite и Postgres, без autogenerate и ORM-моделей, тест в test_migrations.py. Используй, когда нужна новая таблица, колонка или индекс в хранилище харнесса (sessions, events, artifacts, users, reports …).
---

# Миграция хранилища харнесса

Правила — `.claude/rules/storage.md`; устройство — `harness/storage/README.md`; образец —
`harness/storage/migrations/versions/0007_telegram_links.py`.

## Шаги

1. **Номер**: следующий за последним в `harness/storage/migrations/versions/`; `revision = "NNNN"`,
   `down_revision` = предыдущий. Docstring по-русски: зачем таблица/колонка, кто пишет и кто читает.
2. **Руками**, без autogenerate и SQLAlchemy-моделей: `op.create_table`, `op.add_column`, `op.execute`.
   Где диалекты расходятся — ветка `pg = op.get_bind().dialect.name == "postgresql"` (например,
   `TIMESTAMP(timezone=True)` против `Text`, `JSONB` против `Text`).
3. **Не ломай накатанные базы**: новые колонки — nullable или с default; удаление и переименование колонок
   с данными пилота — только через ADR и согласование. Таблица `events` — append-only (триггеры), не трогать.
4. **`downgrade()`** — обратное действие.
5. **Рантайм-код** (`harness/storage/sqlite.py`, `postgres.py` или стор модуля) — на sqlite3/psycopg, оба
   профиля одним изменением.
6. **Тесты**: `tests/test_migrations.py` (свежая база получает схему, колонка реально появилась, idempotent) и
   тест стора на SQLite. Postgres — `tests/test_postgres_storage.py`, если заданы `HARNESS_PG_*`.
7. **Проверка**: `uv run pytest -q`; `uv run python -m harness.cli migrate --status` на локальной SQLite.
   `migrate` на Postgres стенда — только с разрешения пользователя.
8. **Документация**: строка в таблице файлов `harness/storage/README.md`, STATUS.md.
