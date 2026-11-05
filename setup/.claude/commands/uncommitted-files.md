---
description: Обновить чек-лист незакоммиченных файлов uncommitted-files.md (из git status)
---

Запусти `scripts/agent/uncommitted-files.sh` и покажи его вывод. Затем прочитай `uncommitted-files.md` и
сверь с `git status --porcelain --untracked-files=all`: каждый незакоммиченный файл (кроме отмеченных `[x]`)
должен быть в списке. Если расхождение есть — сообщи о нём, файл руками не правь.
