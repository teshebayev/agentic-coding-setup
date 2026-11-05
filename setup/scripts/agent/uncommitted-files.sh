#!/usr/bin/env bash
# Чек-лист незакоммиченных файлов для /uncommitted-files и /fix-uncommitted: uncommitted-files.md в корне.
# Список = текущий git status; отметка [x] сохраняется, пока файл не закоммичен, — разбор можно продолжить.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
list="$root/uncommitted-files.md"

current=$(git -C "$root" status --porcelain --untracked-files=all \
  | cut -c4- | sed 's/.* -> //; s/^"\(.*\)"$/\1/' | grep -vx 'uncommitted-files.md' | sort -u || true)

if [[ -z "$current" ]]; then
  rm -f "$list"
  echo "Незакоммиченных файлов нет."
  exit 0
fi

done_items=""
[[ -f "$list" ]] && done_items=$(sed -n 's/^[0-9]*\. \[x\] //p' "$list")

awk -v done_items="$done_items" '
  BEGIN { n = split(done_items, d, "\n"); for (i = 1; i <= n; i++) if (d[i] != "") checked[d[i]] = 1 }
  { printf "%d. [%s] %s\n", NR, ($0 in checked) ? "x" : " ", $0 }
' <<<"$current" > "$list"

echo "uncommitted-files.md: всего $(grep -c '' "$list"), осталось $(grep -c '\[ \]' "$list" || true)"
