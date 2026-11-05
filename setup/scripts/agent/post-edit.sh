#!/usr/bin/env bash
# PostToolUse-хук Claude Code после Write/Edit: ruff на изменённом .py и инварианты слоёв.
# Ничего не блокирует: замечания уходят Claude через additionalContext.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"

root=${CLAUDE_PROJECT_DIR:-$PWD}
path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
[[ -n "$path" && -f "$path" ]] || exit 0
rel=${path#"$root"/}
notes=""

if [[ "$rel" == *.py ]]; then
  out=$(cd "$root" && uv run --quiet ruff check --output-format concise "$rel" 2>&1) \
    || notes+="ruff:"$'\n'"$out"$'\n\n'
  if [[ "$rel" == harness/* ]] && grep -nE '^\s*(from|import)\s+dwh_analyst_mcp' "$path" >/dev/null; then
    notes+="harness/ импортирует dwh_analyst_mcp — DWH только через MCP-процесс (.claude/rules/mcp-boundary.md):"$'\n'
    notes+="$(grep -nE '^\s*(from|import)\s+dwh_analyst_mcp' "$path")"$'\n\n'
  fi
fi

if [[ "$rel" == harness/config/base.yml || "$rel" == harness/config/dwh.yml ]]; then
  out=$(cd "$root" && uv run --quiet python scripts/agent/check_plugin_layers.py 2>&1) || notes+="$out"$'\n'
fi

[[ -n "$notes" ]] || exit 0
jq -n --arg c "Проверка после правки $rel:"$'\n'"$notes" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}'
