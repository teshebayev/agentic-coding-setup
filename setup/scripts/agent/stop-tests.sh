#!/usr/bin/env bash
# Stop-хук Claude Code: если с прошлого зелёного прогона менялись .py — офлайн-тесты (≈13 с).
# Красные тесты возвращают Claude к работе один раз (stop_hook_active защищает от цикла).
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

input=$(cat)
[[ $(jq -r '.stop_hook_active // false' <<<"$input") == true ]] && exit 0

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Отпечаток изменённых и новых .py; совпал с последним зелёным — тесты не нужны.
fingerprint=$( { git diff HEAD -- '*.py'; git ls-files --others --exclude-standard -- '*.py' | xargs -r cat; } | sha1sum | cut -d' ' -f1)
empty=$(printf '' | sha1sum | cut -d' ' -f1)
stamp="$(git rev-parse --git-dir)/claude-last-green"
[[ "$fingerprint" == "$empty" ]] && exit 0
[[ -f "$stamp" && $(cat "$stamp") == "$fingerprint" ]] && exit 0

if out=$(timeout 300 uv run --quiet pytest -q -x 2>&1); then
  echo "$fingerprint" > "$stamp"
  exit 0
fi
jq -n --arg r "Офлайн-тесты красные после правок .py — почини или объясни пользователю:"$'\n'"$(tail -25 <<<"$out")" \
  '{decision: "block", reason: $r}'
