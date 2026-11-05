# Инструкция агенту: `scripts/agent/guard.sh`

- **Что это:** PreToolUse-хук: запрещает доступ к секретам и опасные команды, спрашивает перед дорогими
- **Когда подхватывается:** перед каждым вызовом Bash/Read/Edit/Write/MultiEdit/NotebookEdit/Grep/Glob (`.claude/settings.json`). Получает JSON вызова на stdin, отвечает JSON с `permissionDecision: deny|ask` или молча выходит (разрешено)
- **Действие при переносе:** **подстроить** — каркас общий, поменять команды, пути и примеры под проект

## Что в файле сейчас (проект «DWH-аналитик»)

- `secret_path` — регэксп путей для файловых инструментов: `.env`, `ACCESS.local.md`, `DWH-Tunnel-*`, `external/`
  (`.env.example` разрешён). `secret_in_cmd` — те же имена внутри Bash-команды.
- deny: секреты; правка `openspec/changes/archive/*` (архив неизменяем); `docker compose config` без `--quiet`.
- ask: `-m live` и `eval.run_control` (живой DWH, платная модель); `dwh_analyst_mcp.marts apply|test|plan|status|cards`;
  `harness.cli ask|chat` без demo-слоя.
- Хук срабатывает и на упоминание секрета в тексте команды (например в heredoc) — это ожидаемая перестраховка.

## Что должно быть в вашем проекте

Тот же каркас (`decide`, разбор `tool_name`, ветки файловых инструментов и Bash) с вашими секретными путями и
вашими опасными командами. deny — только то, что никогда нельзя; ask — то, что можно с разрешения.

## Шаги адаптации

1. Перепиши `secret_path` и `secret_in_cmd` под секретные файлы проекта (`.env*` кроме примеров, `*.pem`,
   `credentials.json`, `secrets/`, kubeconfig…). Список = «никогда» из `testing-runs.md`.
2. Удали проверки `docker compose config` (если docker не используется), `marts`, `harness.cli`, `-m live`.
3. Добавь `ask` для своих опасных команд: деплой, `terraform apply`, миграции на общей БД, `kubectl` в прод-контекст,
   `npm publish`, платные API. Добавь `deny` для того, что нельзя никогда (`git push --force` в main и т.п.).
4. Оставь запрет правки `openspec/changes/archive/*`, если берёте OpenSpec.
5. Дымовые тесты (каждый должен дать ожидаемое решение):
   `echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' | scripts/agent/guard.sh` → deny;
   `echo '{"tool_name":"Read","tool_input":{"file_path":"README.md"}}' | scripts/agent/guard.sh` → пусто;
   `echo '{"tool_name":"Bash","tool_input":{"command":"<ваша опасная команда>"}}' | scripts/agent/guard.sh` → ask.

## Связи с другими файлами

`.claude/settings.json`, `.claude/rules/testing-runs.md`, `.gitignore`, `process-invariants.md` (архив), `CLAUDE.md` (Gotchas).
