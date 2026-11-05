# Инструкция агенту: `.claude/settings.json`

- **Что это:** проектные настройки Claude Code (коммитятся); здесь только три хука
- **Когда подхватывается:** при старте сессии; изменения хуков вступают в силу после перезапуска или проверки в `/hooks`
- **Действие при переносе:** **подстроить** — каркас общий, поменять команды, пути и примеры под проект

## Что в файле сейчас (проект «DWH-аналитик»)

- `PreToolUse` с matcher `Bash|Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob` → `scripts/agent/guard.sh`
  (timeout 10 с): запрет секретов и опасных команд, «спросить» перед дорогими.
- `PostToolUse` с matcher `Edit|Write|MultiEdit` → `scripts/agent/post-edit.sh` (60 с): линтер и проверки слоёв,
  замечания уходят Claude через `additionalContext`.
- `Stop` → `scripts/agent/stop-tests.sh` (320 с): офлайн-тесты, если менялся код.

Пути — через `"$CLAUDE_PROJECT_DIR"`, чтобы хуки работали из любой подпапки.

## Что должно быть в вашем проекте

Те же три хука. Таймаут `Stop` больше таймаута внутри `stop-tests.sh`. Можно добавить `permissions.allow` для
безопасных частых команд (тесты, линт) — это убирает лишние запросы разрешений; секретов и личных путей тут быть
не должно (личное — в `settings.local.json`).

## Шаги адаптации

1. Скопируй как есть; поправь `timeout` у `Stop` под реальное время тестов (+20 с запаса).
2. Проверь зависимости скриптов на машине: `bash`, `jq`, `git`, `sha1sum`, `timeout` (на macOS — `coreutils`).
   Windows без WSL/Git Bash — скрипты придётся переписать.
3. `chmod +x scripts/agent/*.sh`.
4. Открой Claude Code → `/hooks`: должны быть видны три хука. Дымовой тест — в инструкции к `guard.sh`.
5. По желанию — скилл `/fewer-permission-prompts` для allowlist.

## Связи с другими файлами

`scripts/agent/*.sh`, `docs/22-agentic-coding.md` (таблица хуков), `CLAUDE.md` (строка «Hooks»).
