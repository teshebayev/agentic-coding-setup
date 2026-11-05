# Инструкция агенту: `.claude/commands/opsx/archive.md`

- **Что это:** слэш-команда `/opsx:archive [имя]` — проверить готовность, влить дельта-спеки в `openspec/specs/`, перенести изменение в архив
- **Когда подхватывается:** по вызову пользователя; папка `opsx/` даёт префикс `opsx:` в имени команды
- **Действие при переносе:** **не править руками** — файл генерирует OpenSpec CLI, в вашем проекте он появится сам

## Что в файле сейчас (проект «DWH-аналитик»)

Сгенерированный OpenSpec 1.14.3 текст (английский, MIT). Логика совпадает со скиллом `openspec-archive-change`; команда — ручной вход, скилл — автоматический по описанию. Проектные правила подмешиваются из `openspec/config.yaml` через `openspec instructions …`.

## Что должно быть в вашем проекте

Тот же файл, созданный `openspec init` в вашем репозитории.

## Шаги адаптации

1. Не копируй файл руками. Поставь OpenSpec CLI той же версии (Node ≥ 20):
   `npm i -g @fission-ai/openspec@1.14.3 && openspec config set telemetry.enabled false`.
2. В корне целевого репозитория: `openspec init --tools claude --language ru` (язык — ваш). CLI создаст
   `openspec/`, `.claude/commands/opsx/*` и `.claude/skills/openspec-*`. У нас набор: apply, archive, explore,
   propose, sync, update; если части нет — включи её в профиле OpenSpec (`openspec init --profile custom`,
   `openspec config --help`).
3. Затем положи наш `openspec/config.yaml` (адаптированный) — проектные правила живут там, а не в этом файле.
4. После обновления CLI — `openspec update`; ручные правки этого файла будут перезаписаны.
5. Сравни сгенерированный файл с версией из архива (`diff`): если отличаются только версией — всё в порядке.

## Связи с другими файлами

`.claude/skills/openspec-archive-change/SKILL.md`, `openspec/config.yaml`, `.claude/skills/README.md`.
