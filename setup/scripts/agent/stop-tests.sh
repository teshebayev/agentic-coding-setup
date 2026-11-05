#!/usr/bin/env bash
# Stop-хук Claude Code: если файлы, влияющие на тесты, менялись с прошлого прогона, — офлайн-тесты (≈13 с).
# Об одном и том же состоянии файлов сообщает один раз; stop_hook_active защищает от цикла.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
unset PYTHONPATH   # чужой PYTHONPATH (например, ROS) подмешивает в pytest посторонние плагины

# --- Адаптация ---
test_cmd=(uv run --quiet pytest -q -x)
test_timeout=300   # меньше, чем timeout у Stop в settings.json
watch=('*.py' '*.yml' '*.yaml' '*.toml' 'uv.lock')   # всё, от чего зависят тесты
skip=(':!openspec/**' ':!.claude/**')                # артефакты процесса на тесты не влияют

input=$(cat)
[[ $(jq -r '.stop_hook_active // false' <<<"$input") == true ]] && exit 0

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Отпечаток — имена и содержимое файлов на диске, поэтому не зависит от коммитов и индекса: работает в репозитории
# без единого коммита, замечает закоммиченные правки и имена с пробелами.
fingerprint=$(git ls-files -z --cached --others --exclude-standard -- "${watch[@]}" "${skip[@]}" \
  | sort -zu | xargs -0 -r sha1sum 2>/dev/null | sha1sum | cut -d' ' -f1)
git_dir=$(git rev-parse --git-dir)
green="$git_dir/claude-last-green" red="$git_dir/claude-last-red"
[[ -f "$green" && $(cat "$green") == "$fingerprint" ]] && exit 0
[[ -f "$red" && $(cat "$red") == "$fingerprint" ]] && exit 0

out=$(timeout "$test_timeout" "${test_cmd[@]}" 2>&1)
rc=$?

report() {  # report "заголовок": вернуть Claude к работе один раз на это состояние файлов
  echo "$fingerprint" > "$red"
  jq -n --arg r "$1"$'\n'"$(tail -25 <<<"$out")" '{decision: "block", reason: $r}'
  exit 0
}

case "$rc" in
  0) echo "$fingerprint" > "$green"; rm -f "$red" ;;
  5) echo "$fingerprint" > "$green"
     jq -n '{systemMessage: "stop-tests: тесты не найдены, проверять нечего"}' ;;
  1) report "Офлайн-тесты красные — почини или объясни пользователю:" ;;
  124) report "Тесты не уложились в $test_timeout с (завис тест или мало времени) — это не значит, что они зелёные:" ;;
  *) report "Тесты не запустились (код $rc) — вероятнее всего окружение, а не код; разберись или объясни пользователю:" ;;
esac
exit 0
