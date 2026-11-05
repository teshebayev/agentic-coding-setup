#!/usr/bin/env bash
# PreToolUse-хук Claude Code: не даёт читать файлы с доступами и запускать опасные команды.
# deny — вызов отклонён, ask — спросить пользователя. Правила — .claude/rules/testing-runs.md.
# Это страховка, а не граница: обход через интерпретатор (python -c …) список шаблонов не поймает.
# Сбой внутри хука блокирует вызов (exit 2): сломанная защита не должна молча всё пропускать.
set -Eeuo pipefail
trap 'echo "guard.sh: внутренняя ошибка, строка $LINENO — вызов заблокирован" >&2; exit 2' ERR
command -v jq >/dev/null || { echo "guard.sh: нет jq — вызов заблокирован, установи jq" >&2; exit 2; }

input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

decide() {  # decide deny|ask "причина"
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# --- Адаптация: секреты проекта (тот же список — в testing-runs.md, .gitignore, permissions.deny) ---
secret_files='(^|/)\.env(\.[^/]+)?$|(^|/)ACCESS\.local\.md$|(^|/)DWH-Tunnel-|\.pem$|(^|/)id_(rsa|dsa|ecdsa|ed25519)$|(^|/)credentials[^/]*\.json$'
secret_dirs='external|secrets|\.ssh|\.aws|\.gnupg|\.kube'
secret_ok='(^|/)\.env\.(example|sample|template|dist)$'
# Имена, с которыми сравниваются шаблоны оболочки вроде `.e*`.
secret_samples=(.env .env.local .env.production ACCESS.local.md DWH-Tunnel-x credentials.json id_rsa id_ed25519)

# Шаблон считается опасным, только если начинается с того же литерала: `.e*` — да, `*.md` и `*` — нет.
glob_hits_secret() {
  local glob=$1 sample
  for sample in "${secret_samples[@]}"; do
    if [[ "${glob:0:1}" == "${sample:0:1}" && "$sample" == $glob ]]; then return 0; fi
  done
  return 1
}

is_secret_file() {  # для файловых инструментов: каталог опасен и без завершающего /
  [[ "$1" =~ $secret_ok ]] && return 1
  [[ "$1" =~ $secret_files || "$1" =~ (^|/)($secret_dirs)(/|$) ]]
}

mentions_secret() {  # для Bash: разбираем команду на слова; голое слово secrets — ещё не каталог
  local tok tokens=()
  IFS=$' \t\n;|&()<>=:,`' read -r -d '' -a tokens <<<"$1" || true
  for tok in "${tokens[@]}"; do
    [[ "$tok" =~ $secret_ok ]] && continue
    if [[ "$tok" =~ $secret_files || "$tok" =~ (^|/)($secret_dirs)/ ]]; then return 0; fi
    if [[ "$tok" == *[*?[]* ]] && glob_hits_secret "${tok##*/}"; then return 0; fi
  done
  return 1
}

check_rm() {  # один сегмент команды: рекурсивный rm. Широкая цель — deny, обычная — ask, кэши и /tmp — можно
  local seg words=() w seen=0 recursive=0 targets=()
  seg=$(sed -E 's/[0-9]*[<>]+[[:space:]]*[^[:space:]]*//g' <<<"$1")   # перенаправления — не цели удаления
  read -r -a words <<<"$seg" || true
  for w in "${words[@]}"; do
    if ((seen == 0)); then [[ "$w" == rm ]] && seen=1; continue; fi
    case "$w" in
      --recursive) recursive=1 ;;
      --*) ;;
      -*[rR]*) recursive=1 ;;
      -*) ;;
      *) targets+=("$w") ;;
    esac
  done
  ((recursive)) || return 0
  for w in "${targets[@]}"; do
    case "${w%/}" in
      ''|/|/\*|'~'|'~/*'|'$HOME'|'${HOME}'|'$HOME/*'|'$PWD'|'${PWD}'|.|./\*|\*|..|../\*|/home/*[!/]|/[!/]*[!/])
        if [[ "${w%/}" != /*/*/* && "${w%/}" != /tmp/* ]]; then decide deny "rm -r по широкой цели «$w»"; fi ;;
    esac
    case "${w%/}" in
      /tmp/*|'$TMPDIR'/*) ;;
      *) case "${w##*/}" in
           .venv|node_modules|__pycache__|.pytest_cache|.ruff_cache|.mypy_cache|dist|build|.coverage) ;;
           *) decide ask "rm -r «$w» — удаление может быть необратимо" ;;
         esac ;;
    esac
  done
}

check_archive() {  # один сегмент: запись в архив изменений. Разрешён только перенос изменения в архив
  local seg=$1 arch='openspec/changes/archive'
  if [[ "$seg" =~ ^[[:space:]]*cd[[:space:]][^[:space:]]*$arch ]]; then in_archive=1; return 0; fi
  if ((in_archive)) && [[ "$seg" =~ (^|[[:space:]])(rm|mv|cp|touch|truncate|shred|tee)[[:space:]]|sed[[:space:]].*-i|\> ]]; then
    decide deny "Правка внутри архива изменений запрещена (.claude/rules/process-invariants.md)"
  fi
  [[ "$seg" == *"$arch"* ]] || return 0
  [[ "$seg" =~ ^[[:space:]]*mkdir[[:space:]] ]] && return 0
  if [[ "$seg" =~ ^[[:space:]]*mv[[:space:]]+[^[:space:]]*openspec/changes/[^/[:space:]]+/?[[:space:]]+[^[:space:]]*$arch/[^/[:space:]]+/?[[:space:]]*$ ]] \
     && ! [[ "$seg" =~ ^[[:space:]]*mv[[:space:]]+[^[:space:]]*$arch ]]; then
    return 0
  fi
  if [[ "$seg" =~ (^|[[:space:]])(rm|mv|touch|truncate|shred|tee)[[:space:]] \
     || "$seg" =~ (sed|perl)[[:space:]].*-i \
     || "$seg" =~ \>[[:space:]]*[^[:space:]]*$arch \
     || "$seg" =~ (^|[[:space:]])(cp|ln|install|rsync)[[:space:]].*$arch[^[:space:]]*[[:space:]]*$ ]]; then
    decide deny "Архив изменений неизменяем — создай новое изменение с Supersedes (.claude/rules/process-invariants.md)"
  fi
}

case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Glob)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""' <<<"$input")
    rel=${path#"${CLAUDE_PROJECT_DIR:-$PWD}"/}
    rel=${rel#./}
    if [[ -n "$rel" ]] && is_secret_file "$rel"; then
      decide deny "$rel — доступы или реальные данные; не читать и не цитировать (CLAUDE.md, Gotchas)"
    fi
    # Grep по glob и Glob по шаблону тоже находят файлы: pattern у Grep — это текст, он не проверяется.
    glob=""
    [[ "$tool" == Grep ]] && glob=$(jq -r '.tool_input.glob // ""' <<<"$input")
    [[ "$tool" == Glob ]] && glob=$(jq -r '.tool_input.pattern // ""' <<<"$input")
    if [[ -n "$glob" ]] && { is_secret_file "$glob" || glob_hits_secret "${glob##*/}"; }; then
      decide deny "Шаблон «$glob» находит файлы с доступами"
    fi
    if [[ "$tool" != Read && "$tool" != Grep && "$tool" != Glob && "$rel" == openspec/changes/archive/* ]]; then
      decide deny "Архив изменений неизменяем — создай новое изменение с Supersedes (.claude/rules/process-invariants.md)"
    fi
    ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
    clean=${cmd//[\"\'\\]/}   # кавычки и обратный слеш не должны прятать имя: .en''v → .env

    # --- Секреты ---
    if mentions_secret "$clean"; then
      decide deny "Команда трогает файл с доступами; используй .env.example, а для поиска — инструмент Grep"
    fi

    # --- Общие проверки: опасное для любого проекта ---
    # `<команда> --help` с фильтром вывода ничего не выполняет; секреты уже проверены выше.
    help_only='^[^;&|`$]*[[:space:]]--help([[:space:]][^;&|`$]*)?(\|[[:space:]]*(grep|head|tail|less|wc)[^;&|`$]*)*$'
    if [[ "$cmd" != *$'\n'* && "$cmd" =~ $help_only ]]; then exit 0; fi

    if [[ "$clean" =~ git[^\;\&\|]*[[:space:]]push[^\;\&\|]*([[:space:]]--force([[:space:]]|$)|[[:space:]]-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)|[[:space:]]\+[^[:space:]]) ]]; then
      decide deny "git push с перезаписью истории запрещён"
    fi
    if [[ "$clean" =~ git[^\;\&\|]*[[:space:]]--no-verify ]]; then
      decide deny "--no-verify обходит проверки; почини причину, а не проверку"
    fi
    if [[ "$clean" =~ (curl|wget)[^\;\&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$) || "$clean" =~ (curl|wget)[^\;\&]*\|[[:space:]]*(sudo[[:space:]]+)?(python[0-9.]*|node|perl|ruby)([[:space:]]|$) || "$clean" =~ (ba|z)?sh[[:space:]]+\<\([[:space:]]*(curl|wget) ]]; then
      decide deny "Выполнение скрипта из сети без просмотра запрещено; скачай и покажи пользователю"
    fi
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])mkfs([.[:space:]]|$) || "$clean" =~ (^|[[:space:]\;\&\|])dd[[:space:]][^\;\&\|]*of=/dev/ ]]; then
      decide deny "Команда пишет прямо в устройство"
    fi

    in_archive=0
    while IFS= read -r seg; do
      check_archive "$seg"
      check_rm "$seg"
    done < <(sed 's/[;&|]\+/\n/g' <<<"$clean")

    # Потеря незакоммиченной работы, публикация, правда root — только с разрешения.
    if [[ "$clean" =~ git[^\;\&\|]*[[:space:]]reset[[:space:]][^\;\&\|]*--hard || "$clean" =~ git[^\;\&\|]*[[:space:]]clean[[:space:]][^\;\&\|]*-[a-zA-Z]*f \
       || "$clean" =~ git[^\;\&\|]*[[:space:]]checkout[^\;\&\|]*[[:space:]]--?[[:space:]]+\. || "$clean" =~ git[^\;\&\|]*[[:space:]]checkout[[:space:]]+\.([[:space:]]|$) \
       || "$clean" =~ git[^\;\&\|]*[[:space:]]branch[[:space:]][^\;\&\|]*-D || "$clean" =~ git[^\;\&\|]*[[:space:]]stash[[:space:]]+(drop|clear) ]]; then
      decide ask "Команда git может безвозвратно потерять незакоммиченную работу или коммиты"
    fi
    if [[ "$clean" =~ git[^\;\&\|]*[[:space:]]restore[[:space:]] ]] && ! [[ "$clean" =~ --staged ]]; then
      decide ask "git restore отбрасывает незакоммиченные правки"
    fi
    if [[ "$clean" =~ git[^\;\&\|]*[[:space:]]push([[:space:]]|$) ]]; then
      decide ask "git push публикует изменения"
    fi
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])sudo[[:space:]] ]]; then
      decide ask "Команда с sudo"
    fi

    # Чтение всего дерева захватывает и файлы с доступами.
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])[ef]?grep[[:space:]][^\;\&\|]*(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[[:space:]] && "$clean" =~ [[:space:]](\.|\./|\.\./?|~/?|\$HOME/?|/)([[:space:]]|$) ]]; then
      decide ask "grep -r по всему дереву читает и файлы с доступами; инструмент Grep учитывает .gitignore"
    fi
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])rg[[:space:]][^\;\&\|]*(--no-ignore|--unrestricted|[[:space:]]-u+)([[:space:]]|$) ]]; then
      decide ask "rg без .gitignore читает и файлы с доступами"
    fi
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])(tar|zip)[[:space:]][^\;\&\|]*[[:space:]]\.(/)?([[:space:]]|$) ]]; then
      decide ask "Архив всего дерева захватит и файлы с доступами"
    fi
    if [[ "$clean" =~ (^|[[:space:]\;\&\|])(env|printenv)([[:space:]]|$)[^\;\&]*([Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww]) ]]; then
      decide ask "Вывод секретов из окружения"
    fi

    # --- Адаптация: опасные команды проекта ---
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
