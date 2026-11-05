# Инструкция агенту: `scripts/agent/guard.sh`

- **Что это:** PreToolUse-хук: запрещает доступ к секретам и опасные команды, спрашивает перед дорогими
- **Когда подхватывается:** перед каждым вызовом Bash/Read/Edit/Write/MultiEdit/NotebookEdit/Grep/Glob (`.claude/settings.json`). Получает JSON вызова на stdin, отвечает JSON с `permissionDecision: deny|ask` или молча выходит (разрешено). Ошибка самого хука блокирует вызов: `exit 2` в коде и `onFailure: block` в настройках
- **Действие при переносе:** **подстроить** — правятся только блоки с пометкой «Адаптация», остальное общее

## Что в файле сейчас (проект «DWH-аналитик»)

- **Адаптация, секреты:** `secret_files`, `secret_dirs`, `secret_ok` (что можно: `.env.example` и т.п.), `secret_samples`
  (имена для сравнения с шаблонами оболочки вроде `.e*`). В списках есть и общее: `.env.*`, `*.pem`, ключи SSH, `.ssh`, `.aws`, `.kube`.
- **Общее, не менять:** разбор команды на слова без кавычек (`.en''v`, `git show :.env`, `f=.env`); `--help` с фильтром
  вывода ничего не выполняет; deny — `git push --force`, `--no-verify`, `curl | sh`, запись в устройство, `rm -r` по широкой
  цели, запись в архив изменений и через Bash (перенос изменения в архив разрешён); ask — `git push`, потеря незакоммиченной
  работы, `sudo`, обычный `rm -r` (кэши и `/tmp` можно), чтение всего дерева, вывод секретов из окружения.
- **Адаптация, опасные команды проекта:** `docker compose config`, `-m live`, `eval.run_control`, `marts`, `harness.cli`.
- Упоминание секрета в тексте команды (heredoc, сообщение коммита) тоже срабатывает — это ожидаемая перестраховка.

## Что должно быть в вашем проекте

Тот же файл с вашими блоками «Адаптация». deny — только то, что никогда нельзя; ask — то, что можно с разрешения.
Хук — страховка, а не граница: `python -c` и `ls | xargs cat` он не поймает. Не обещайте большего в документации.

## Шаги адаптации

1. Перепиши `secret_files`, `secret_dirs`, `secret_samples` под секреты проекта; убери `ACCESS.local.md`, `DWH-Tunnel-`,
   `external`. Тот же список — в «никогда» из `testing-runs.md`, `.gitignore`, `permissions.deny` и `secret_files` в `doctor.sh`.
2. Замени блок «опасные команды проекта»: деплой, `terraform apply`, миграции на общей БД, `kubectl` в прод-контекст,
   `npm publish`, платные API. Блок общих проверок не трогай.
3. Дымовые тесты (каждый должен дать ожидаемое решение):
   `echo '{"tool_name":"Read","tool_input":{"file_path":".env"}}' | scripts/agent/guard.sh` → deny;
   `echo '{"tool_name":"Bash","tool_input":{"command":"cat .e*"}}' | scripts/agent/guard.sh` → deny;
   `echo '{"tool_name":"Read","tool_input":{"file_path":"README.md"}}' | scripts/agent/guard.sh` → пусто;
   `echo '{"tool_name":"Bash","tool_input":{"command":"<ваша опасная команда>"}}' | scripts/agent/guard.sh` → ask;
   `echo 'битый JSON' | scripts/agent/guard.sh; echo $?` → 2.
4. Проверь, что обычная работа не прерывается: тесты, линт, `git status`, `git commit`, `grep -rn x src/` → пусто.

## Связи с другими файлами

`.claude/settings.json`, `.claude/rules/testing-runs.md`, `.gitignore`, `process-invariants.md` (архив), `CLAUDE.md` (Gotchas).
