#!/usr/bin/env bash
# SessionStart-хук Claude Code: проверяет, что защита и процесс сетапа реально работают на этой машине.
# Никогда не блокирует сессию. Всё в порядке — молчит; иначе замечания видят и Claude, и пользователь.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

# --- Адаптация ---
required=(jq git sha1sum timeout uv)   # что нужно хукам и командам проекта
openspec_version=1.14.3                # пустая строка — OpenSpec не берём
min_claude=2.1.295                     # с этой версии работает onFailure: block
want_plugin=superpowers                # пустая строка — плагин не нужен
secret_files=(.env ACCESS.local.md)    # что не должно попасть в git

notes=()
version_lt() { [[ "$1" != "$2" && $(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1) == "$1" ]]; }

for tool in "${required[@]}"; do
  command -v "$tool" >/dev/null || notes+=("нет $tool: хуки не смогут работать")
done
for script in scripts/agent/*.sh; do
  [[ -x "$script" ]] || notes+=("$script не исполняемый: выполни chmod +x")
done

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  notes+=("это не git-репозиторий: stop-tests.sh и /uncommitted-files не работают")
else
  for f in "${secret_files[@]}"; do
    if [[ -n $(git ls-files -- "$f") ]]; then
      notes+=("$f уже в git: это утечка, убери из индекса и смени доступы")
    elif [[ -e "$f" ]] && ! git check-ignore -q -- "$f"; then
      notes+=("$f не в .gitignore: его легко закоммитить")
    fi
  done
fi

if [[ -f .pre-commit-config.yaml ]] && git rev-parse --git-dir >/dev/null 2>&1; then
  hook=$(git rev-parse --git-path hooks/pre-commit)
  [[ -x "$hook" ]] || notes+=("pre-commit не установлен: секреты и линт не проверяются при коммите; выполни uvx pre-commit install")
fi

if [[ -n "${PYTHONPATH:-}" ]]; then
  notes+=("задан PYTHONPATH=$PYTHONPATH: он подмешивается в venv и может ломать pytest; команды запускай через env -u PYTHONPATH")
fi

if [[ -n "$openspec_version" && -d openspec ]]; then
  if ! command -v openspec >/dev/null; then
    notes+=("нет openspec: /opsx:* не работают; npm i -g @fission-ai/openspec@$openspec_version")
  else
    have=$(OPENSPEC_TELEMETRY=0 timeout 5 openspec --version 2>/dev/null | tail -1)
    [[ "$have" == "$openspec_version" ]] || notes+=("openspec $have вместо $openspec_version: сгенерированные скиллы могут разойтись с CLI")
  fi
fi

if command -v claude >/dev/null; then
  have=$(timeout 5 claude --version 2>/dev/null | awk '{print $1}')
  if [[ -n "$have" ]] && version_lt "$have" "$min_claude"; then
    notes+=("Claude Code $have старее $min_claude: onFailure: block не работает, сломанный guard.sh будет всё пропускать")
  fi
fi

if [[ -n "$want_plugin" ]] && command -v jq >/dev/null; then
  enabled=$(jq -r --arg p "$want_plugin@" \
    '(.enabledPlugins // {}) | to_entries | any(.value == true and (.key | startswith($p)))' \
    "$HOME/.claude/settings.json" .claude/settings.json 2>/dev/null | grep -c true)
  [[ "$enabled" -gt 0 ]] || notes+=("не включён плагин $want_plugin: процесс на него опирается; поставь через /plugin или убери упоминания")
fi

((${#notes[@]})) || exit 0
text="Проверка сетапа (scripts/agent/doctor.sh):"$'\n'$(printf -- '- %s\n' "${notes[@]}")
if command -v jq >/dev/null; then
  jq -n --arg t "$text" \
    '{systemMessage: $t, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $t}}'
else
  echo "$text"
fi
exit 0
