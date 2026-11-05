# Инструкция агенту: `.claude/settings.json`

- **Что это:** проектные настройки Claude Code (коммитятся): четыре хука, запреты на чтение секретов, очистка `PYTHONPATH`
- **Когда подхватывается:** при старте сессии; изменения хуков вступают в силу после перезапуска или проверки в `/hooks`
- **Действие при переносе:** **подстроить** — каркас общий, поменять команды, пути и примеры под проект

## Что в файле сейчас (проект «DWH-аналитик»)

- `env.PYTHONPATH: ""` — чужой `PYTHONPATH` (например, ROS) ломает pytest в venv.
- `permissions.deny` — второй слой к `guard.sh` для `Read`: `.env`, `.env.local`, `*.pem`, `~/.ssh`, `~/.aws`, `~/.kube`,
  наши файлы с доступами. `Read(./.env.*)` намеренно нет: deny сильнее любых исключений и закрыл бы `.env.example`.
- `SessionStart` с matcher `startup` → `scripts/agent/doctor.sh` (20 с): проверка, что сетап работает на этой машине.
- `PreToolUse` с matcher `Bash|Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob` → `scripts/agent/guard.sh`
  (10 с, `onFailure: block`): не запустившийся guard блокирует вызов, а не пропускает его. Нужен Claude Code ≥ 2.1.295.
- `PostToolUse` с matcher `Edit|Write|MultiEdit` → `scripts/agent/post-edit.sh` (60 с): линтер и проверки слоёв,
  замечания уходят Claude через `additionalContext`.
- `Stop` → `scripts/agent/stop-tests.sh` (320 с): офлайн-тесты, если менялись файлы, от которых они зависят.

Пути — через `"$CLAUDE_PROJECT_DIR"`, чтобы хуки работали из любой подпапки.

## Что должно быть в вашем проекте

Те же четыре хука и `onFailure: block` на guard. Таймаут `Stop` больше `test_timeout` в `stop-tests.sh`. Можно добавить
`permissions.allow` для безопасных частых команд (тесты, линт) — это убирает лишние запросы разрешений; секретов и
личных путей тут быть не должно (личное — в `settings.local.json`).

## Шаги адаптации

1. Скопируй как есть; поправь `timeout` у `Stop` под реальное время тестов (+20 с запаса).
2. В `permissions.deny` замени наши файлы своими. Правило `Read` не закрывает Bash полностью и не видит чтение через
   подпроцессы, поэтому guard всё равно нужен.
3. Проект не на Python или ему нужен `PYTHONPATH` — убери блок `env`.
4. Проверь зависимости скриптов на машине: `bash`, `jq`, `git`, `sha1sum`, `timeout` (на macOS — `coreutils`).
   Windows без WSL/Git Bash — скрипты придётся переписать.
5. `chmod +x scripts/agent/*.sh`.
6. Открой Claude Code → `/hooks`: должны быть видны четыре хука. Дымовой тест — в инструкции к `guard.sh`.
7. По желанию — скилл `/fewer-permission-prompts` для allowlist.

## Связи с другими файлами

`scripts/agent/*.sh`, `docs/22-agentic-coding.md` (таблица хуков), `CLAUDE.md` (строка «Hooks»).
