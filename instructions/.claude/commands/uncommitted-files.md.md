# Инструкция агенту: `.claude/commands/uncommitted-files.md`

- **Что это:** слэш-команда `/uncommitted-files`: обновить чек-лист незакоммиченных файлов
- **Когда подхватывается:** по вызову пользователя `/uncommitted-files`
- **Действие при переносе:** **оставить как есть** — файл общий, правка не нужна

## Что в файле сейчас (проект «DWH-аналитик»)

Запускает `scripts/agent/uncommitted-files.sh`, показывает вывод, сверяет `uncommitted-files.md` с `git status`; файл руками не правит.

## Что должно быть в вашем проекте

То же.

## Шаги адаптации

Скопируй как есть. Проверь, что `/uncommitted-files.md` есть в `.gitignore`.

## Связи с другими файлами

`scripts/agent/uncommitted-files.sh`, `/fix-uncommitted`.
