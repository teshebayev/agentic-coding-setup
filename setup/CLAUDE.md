# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An agent harness ("DWH-аналитик") that answers questions about a data warehouse: the LLM writes SQL, the
harness validates it, runs it read-only through an MCP server, and checks the final answer. All docs, code
comments, commit messages, OpenSpec artifacts, `GLOSSARY.md` and ADRs are in **Russian**. Keep writing them in Russian.

IMPORTANT: read the surrounding code, tests and the module's `README.md` before writing new code.

## Commands

Python 3.12, managed with `uv` (workspace: root `harness` package + `dwh-analyst-mcp/` member).

```bash
uv sync                                         # installs dev + notebooks groups by default
uv run pytest -q                                # offline, ~13 s; tests/ and dwh-analyst-mcp/tests/
uv run pytest tests/test_loop.py::test_name -q  # single test
uv run ruff check .                             # errors only (F, E9); no formatter
uv run pytest eval -m live                      # playbook regression against the live DWH — ask first

# Offline demo: no API key, no DWH, no docker (SQLite + scripted model, frozen date)
uv run python -m harness.cli seed-demo
uv run python -m harness.cli --layers base.yml,dwh.yml,demo.yml ask "Сколько отгрузок по KOTON за прошлую неделю?"

# Real run: default profile needs Postgres + MinIO containers, DWH via SSH tunnel on 127.0.0.1:15432
docker compose up -d postgres minio
uv run python -m harness.cli ask "…"            # also: chat, events ID, verify ID, fork ID SEQ
uv run python -m harness.cli context ID         # per-step context breakdown: tokens, cache, injector accuracy
uv run python -m harness.cli turns-report --since YYYY-MM-DD [--out x.xlsx]
uv run python -m harness.cli migrate [--status]
uv run uvicorn harness.api.app:create_app --factory --port 8080   # needs HARNESS_API_KEY (or HARNESS_ALLOW_NO_AUTH=1)
uv run python -m eval.run_control eval/control_questions.example.yml

# Marts as code (dwh-knowledge/marts/ → mart_spark_server + dwh_meta). Only `apply` writes, via MARTS_DB_*
uv run python -m dwh_analyst_mcp.marts check|test NAME|plan|apply NAME [--run-now]|status|cards
```

Tests are fully offline: `tests/conftest.py` sets `HARNESS_NO_DOTENV=1` and `HARNESS_ALLOW_NO_AUTH=1`, seeds the
demo DWH and forces SQLite storage. What may run without asking (live DWH, paid model, `marts apply` may not):
`.claude/rules/testing-runs.md`.

## Architecture (big picture)

Start-up: `load_config()` → `build_context()` (`harness/core/bootstrap.py`) → `running_context()` →
`AgentLoop.run_turn()` (`harness/core/loop.py`). CLI, API, eval, notebooks and tests all use this path.
Package map: `harness/README.md`.

- **Everything is a plugin; config decides what is active.** Config layers merge deeply but **lists replace
  wholesale**, so a plugin goes into every layer that has `plugins:` → `.claude/rules/plugins.md`.
- **The event log is the single source of truth; replay stays deterministic** (`build_request` is pure,
  `harness.cli verify` compares `request_hash`) → `.claude/rules/event-log.md`.
- **The DWH is reached only through MCP** (`dwh-analyst-mcp/`, separate process); `harness/` never imports
  `dwh_analyst_mcp` → `.claude/rules/mcp-boundary.md`.
- **Two storage profiles** (Postgres + MinIO, SQLite + files) share protocols; Alembic migrations are
  hand-written → `.claude/rules/storage.md`.
- **Curated knowledge** in `dwh-knowledge/` grows only through analyst review, never by the harness agent
  writing there → `.claude/rules/knowledge.md`, `harness/memory/README.md`.
- **Managers use LibreChat** (`ui/librechat/`) via the OpenAI-compatible `/v1/chat/completions`
  (`harness/api/openai_compat.py`). The harness keeps its own history keyed by `X-Conversation-Id`; an
  `X-User-Id` not registered with `harness.cli create-user` gets `403`.

## Gotchas

- `demo.yml` pins `prompt.now` to 2026-09-17. The scripted demo and `answer_check` depend on that frozen date.
- CLI and API exit via `harness/core/hard_exit.py`. Otherwise pyarrow crashes the process with code 134 at
  shutdown. Don't "clean this up".
- The DWH timezone is `Asia/Tashkent` (`prompt.timezone`). "Last week" and similar periods are computed there.
- Never run `docker compose config` without `--quiet`. It prints the secrets from `.env` (a hook blocks it).
- `.env`, `ACCESS.local.md`, `DWH-Tunnel-*`, `external/` and `data/` are local and gitignored and contain
  credentials or real data. Don't read them into the conversation or quote them into committed files.

## Development workflow (OpenSpec)

```
/grill-with-docs  or  /opsx:explore   →   /opsx:propose   →   /opsx:apply   →   /opsx:archive
   (fuzzy idea, same session as propose)                     (fresh session;
                                                              /opsx:apply-sequential for big changes)
```

- Changes live in `openspec/changes/<name>/`, archive in `openspec/changes/archive/`, stable specs in
  `openspec/specs/`. Project context and artifact rules: `openspec/config.yaml`. Process overview:
  `docs/22-agentic-coding.md`.
- Run `/grill-with-docs` on its own, never from inside `/opsx:*`; then `/opsx:propose` in the same session
  must carry every agreed decision into the proposal.
- This workflow replaces superpowers' brainstorming/writing-plans for changes in this repo. Inside
  `/opsx:apply` use superpowers' test-driven-development, systematic-debugging and
  verification-before-completion.
- Trivial fixes (typo, one-line bug with a test) don't need a change — just do them.
- Domain skills: `harness-plugin`, `dwh-playbook`, `alembic-migration`, `split-large-tests`; subagent
  `replay-reviewer` before finishing changes to `harness/core|context|llm`. Commands: `/uncommitted-files`,
  `/fix-uncommitted`, `/refactor-claude-md`. `.mcp.json` exposes the demo `dwh-analyst` MCP server
  (run `harness.cli seed-demo` once).
- Hooks (`.claude/settings.json`, scripts in `scripts/agent/`): a guard blocks secret files and dangerous
  commands; after edits ruff and layer checks run; on stop the offline test suite runs if `.py` changed.

## Rules (`.claude/rules/`)

| Rule file | Scope | What it covers |
|---|---|---|
| `traceability.md` | global | Requirement IDs and where to reference them |
| `process-invariants.md` | global | Change naming, immutable archive, file size, docs in the same change |
| `antipatterns.md` | global | Process and harness-specific mistakes |
| `tdd-workflow.md` | global | Red-green-refactor with pytest |
| `test-planning.md` | global | Automated checks per level in tasks.md |
| `testing-runs.md` | global | What may run without asking |
| `proposal-format.md`, `delta-specs.md`, `design-decisions.md` | `openspec/**` | OpenSpec artifacts |
| `adr.md` | `docs/adr/**` | When and how to write an ADR |
| `glossary.md` | `GLOSSARY.md` | Development glossary vs DWH business terms |
| `event-log.md` | `harness/core`, `context`, `llm` | Event log, replay, prompt cache prefix |
| `plugins.md` | `harness/**` | Plugins, hooks, config layers |
| `storage.md` | `harness/storage/**` | Two profiles, hand-written migrations |
| `mcp-boundary.md` | `dwh-analyst-mcp/**`, MCP client, guards | MCP boundary, SQL guard, answer check |
| `knowledge.md` | `dwh-knowledge/**` | Cards, playbooks, generated cards, knowledge loop |
| `docs.md` | `docs/**`, `README.md`, `STATUS.md` | Which document is for what |
