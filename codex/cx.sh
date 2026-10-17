#!/bin/bash
# cx.sh - Codex roles that mirror the Claude sub-agents in ../agents/ (settings chosen from the measurements in ../results/).
#
# usage: cx.sh <lecteur|chercheur|executant|relecteur|architecte|analyste|enqueteur|chasseur-erreurs|securite-web|seo> "<prompt>" [directory]
#
# The last three roles reuse the body of the Claude agent file $CX_AGENTS_DIR/<role>.md (single source of truth).
# Call it WITHOUT shell redirection (> file): the output comes back in the calling tool's result.
#
# Environment variables (all optional):
#   CX_AGENTS_DIR   directory holding the agent .md files        (default: $HOME/.claude/agents)
#   CX_LOG          token log file, one line per call            (default: $HOME/.cx_tokens.log)
#   CX_NODE_DIR     directory containing node/codex to prepend to PATH (default: empty = rely on PATH)
#   CX_WIN_SANDBOX  Windows sandbox mode for Codex ("unelevated"; set to "none" on Linux/macOS) (default: unelevated)
#   CX_M_*          override the model of a role, e.g. CX_M_EXECUTANT=gpt-6-sol (see table below)
#
# Model names below are the ones available on the author's OpenAI account at measurement time:
# replace them with the models your account offers.

role="$1"; prompt="$2"; dir="${3:-.}"

AGENTS_DIR="${CX_AGENTS_DIR:-$HOME/.claude/agents}"
LOG="${CX_LOG:-$HOME/.cx_tokens.log}"
WIN_SANDBOX="${CX_WIN_SANDBOX:-unelevated}"

# --- Windows / Git Bash specific: make `codex` (a .cmd shim) and Node reachable. -------------------
# On Linux/macOS leave CX_NODE_DIR unset; nothing is changed.
[ -n "$CX_NODE_DIR" ] && export PATH="$CX_NODE_DIR:$PATH"

# role -> model, reasoning effort, sandbox, extra flags
case "$role" in
  lecteur)    m="${CX_M_LECTEUR:-gpt-6-luna}";    e=low;    s=read-only;       extra="" ;;
  chercheur)  m="${CX_M_CHERCHEUR:-gpt-6-luna}";  e=low;    s=read-only;       extra="--search" ;;
  executant)  m="${CX_M_EXECUTANT:-gpt-6-sol}";   e=low;    s=workspace-write; extra="" ;;
  relecteur)  m="${CX_M_RELECTEUR:-gpt-6-sol}";   e=medium; s=read-only;       extra="" ;;
  architecte) m="${CX_M_ARCHITECTE:-gpt-6-astra}"; e=high;  s=read-only;       extra="" ;;
  analyste)   m="${CX_M_ANALYSTE:-gpt-6-astra}";  e=medium; s=read-only;       extra="" ;; # routine investigation / audit
  enqueteur)  m="${CX_M_ENQUETEUR:-gpt-6-astra}"; e=high;   s=read-only;       extra="" ;; # hard investigation. Never xhigh.
  chasseur-erreurs|securite-web|seo)
    m="${CX_M_REVIEW:-gpt-6-sol}"; e=medium; s=read-only; extra=""
    f="$AGENTS_DIR/$role.md"
    # strip the YAML front matter (everything up to the 2nd '---') and prepend the agent body to the prompt
    prompt="$(awk 'c>=2{print} /^---$/{c++}' "$f")

Consigne : $prompt" ;;
  *) echo "unknown role: $role" >&2; exit 2 ;;
esac

# The reader role is told how to read files from the sandbox (PowerShell wording kept: measured on Windows).
[ "$role" = lecteur ] && prompt="Lis les fichiers avec Get-Content / Select-String (tu as accès au disque en lecture). $prompt"

# --- Windows specific: the sandbox flag below only exists on Windows builds of Codex. ---------------
sandbox_args=()
[ "$WIN_SANDBOX" != "none" ] && sandbox_args=(-c "windows.sandbox=\"$WIN_SANDBOX\"")

# stdin is closed (< /dev/null) so codex never waits for interactive input.
out=$(codex $extra exec --skip-git-repo-check -C "$dir" -m "$m" \
      -c "model_reasoning_effort=\"$e\"" -s "$s" "${sandbox_args[@]}" "$prompt" < /dev/null 2>&1)
rc=$?
printf '%s\n' "$out"

# Log the tokens reported by codex ("tokens used" line followed by the number).
tok=$(printf '%s\n' "$out" | grep -A1 'tokens used' | tail -1 | tr -d ' ,')
mkdir -p "$(dirname "$LOG")"
echo "$(date '+%F %T') $role $m $e rc=$rc $tok" >> "$LOG"

[ "$rc" -ne 0 ] && echo "cx.sh: codex failed (exit code $rc), result NOT reliable" >&2
exit "$rc"
