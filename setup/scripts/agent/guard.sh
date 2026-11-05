#!/usr/bin/env bash
# PreToolUse-хук Claude Code: не даёт читать файлы с доступами и запускать опасные команды.
# deny — вызов отклонён, ask — спросить пользователя. Правила — .claude/rules/testing-runs.md.
set -euo pipefail

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

decide() {  # decide deny|ask "причина"
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# Файлы с доступами и реальными данными; .env.example и прочие .env.* — можно.
secret_path='(^|/)(\.env|ACCESS\.local\.md)$|(^|/)DWH-Tunnel-|(^|/)external(/|$)'
secret_in_cmd='(^|[[:space:]/"'"'"'=])(\.env|ACCESS\.local\.md)($|[[:space:]"'"'"';|&)])|DWH-Tunnel-|(^|[[:space:]"'"'"'])(\./)?external/'

case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""' <<<"$input")
    rel=${path#"${CLAUDE_PROJECT_DIR:-$PWD}"/}
    if [[ -n "$rel" && "$rel" =~ $secret_path ]]; then
      decide deny "$rel — доступы или реальные данные; не читать и не цитировать (CLAUDE.md, Gotchas)"
    fi
    if [[ "$tool" != Read && "$tool" != Grep && "$tool" != Glob && "$rel" == openspec/changes/archive/* ]]; then
      decide deny "Архив изменений неизменяем — создай новое изменение с Supersedes (.claude/rules/process-invariants.md)"
    fi
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    if [[ "$cmd" =~ $secret_in_cmd ]]; then
      decide deny "Команда трогает .env, ACCESS.local.md, DWH-Tunnel-* или external/ — там доступы; используй .env.example"
    fi
    if [[ "$cmd" =~ docker[\ -]compose([^|;&]*)[[:space:]]config ]] && ! [[ "$cmd" =~ (--quiet|--services|--volumes|--profiles|--images|[[:space:]]-q([[:space:]]|$)) ]]; then
      decide deny "docker compose config без --quiet печатает секреты из .env"
    fi
    if [[ "$cmd" =~ -m[[:space:]]*[\"\']?live || "$cmd" =~ eval\.run_control ]]; then
      decide ask "Живой DWH и/или платная модель (.claude/rules/testing-runs.md)"
    fi
    if [[ "$cmd" =~ dwh_analyst_mcp\.marts[[:space:]]+(apply|test|plan|status|cards) ]]; then
      decide ask "Команда витрин ходит в базу витрин; apply — пишет в mart_spark_server"
    fi
    if [[ "$cmd" =~ harness\.cli([^|;&]*)[[:space:]](ask|chat)([[:space:]]|$) ]] && ! [[ "$cmd" =~ demo\.yml|--llm[[:space:]]+demo ]]; then
      decide ask "harness.cli ask/chat без demo-слоя идёт в OpenRouter и живой DWH"
    fi
    ;;
esac
exit 0
