# Правило: что можно запускать без спроса

**Свободно:** `uv run pytest -q` (офлайн, ≈13 с), отдельные тесты, `uv run ruff check`, offline-демо
(`--layers base.yml,dwh.yml,demo.yml`), `harness.cli verify` / `events` / `context` по локальным сессиям,
`marts check|sql` (офлайн), `openspec …`.

**Только с явного разрешения пользователя** (живой DWH, деньги, общие стенды):
- `uv run pytest eval -m live`, `python -m eval.run_control` — живой DWH и платная модель;
- `harness.cli ask|chat` с профилем по умолчанию — OpenRouter и DWH через туннель;
- `python -m dwh_analyst_mcp.marts test|plan|status|cards` — ходят в базу витрин;
- `python -m dwh_analyst_mcp.marts apply` — единственная пишущая команда, пишет в `mart_spark_server`;
- `docker compose up/down/restart` на стенде, `harness.cli migrate` на Postgres.

**Никогда:** `docker compose config` без `--quiet` (печатает секреты из `.env`); чтение или цитирование
`.env`, `ACCESS.local.md`, `DWH-Tunnel-*`, `external/` — там доступы и реальные данные.
