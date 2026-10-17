# Minimal global CLAUDE.md (example)

Copy to `~/.claude/CLAUDE.md` and adapt. Short on purpose: this file is re-read on every message.

## Models and effort
- Default model: Sonnet, effort medium. Higher effort only when asked.
- Opus only through the `architecte` sub-agent (or in a dedicated conversation for a hard design task),
  never switched on mid-conversation (changing model or effort rebuilds the whole prompt cache).

## Sub-agents, graded by task
- Haiku: very simple, mechanical work (search, list, count, run a command and report its output) -> `lecteur`, `testeur`.
- Sonnet: the rest of the execution (write already-designed code, targeted fixes) -> `executant`, `chercheur`.
- The main thread designs, decides, and verifies. It does not do bulk reading/writing/testing itself:
  3+ files or ~300 lines to read -> `lecteur`; code > ~30 lines already designed -> `executant`;
  test suites / long outputs -> `testeur`.
- Never more agents than needed: an agent costs ~20-30k tokens of cache at start-up. It is worth it only if it
  saves the main thread more than ~30k tokens of reading or output.
- An agent that is stuck (same error 2-3 times) stops and reports what it tried; it never loops.

## When to call `architecte` (Opus, medium)
Do not wait to "feel stuck". Call it when:
1. a test still fails after 2 corrections;
2. you are about to write a workaround or a special case to make a test pass;
3. two tests (or a test and the doc) contradict each other;
4. the report you are about to hand over contains "serious doubts" / "not verified";
5. there is no progress after 2 checkpoints, or the same error trace keeps coming back.
Short brief: goal, files, what was tried, exact error. Its plan must only require commands the session can run
(e.g. pytest), with a fallback; if a command is refused, adapt instead of stopping.

## No workarounds
If making a test pass requires an exception or special case, or two tests contradict each other: do NOT code the
workaround. Leave the test red, call `architecte` or ask the user to decide.

## Optional: Codex (OpenAI) as implementer
Only if `codex` is installed, logged in and has quota; otherwise skip this step and use the Claude-only pipeline.
- Linear chain: Codex implements ONCE (`cx.sh executant`), then Claude verifies ONCE (no sub-agents, no
  back-and-forth). Never accept Codex output as is.
- The Codex brief must: give the direct test command (the venv's python + pytest, not a wrapper script); say
  "adapt existing tests that the plan contradicts to the new contract, without weakening them, and list them";
  say "an answer without any modified file is a failure".
- Hard investigations (multi-file bug hunts): `cx.sh enqueteur` then one Claude verification.

## Context hygiene
- Keep this file and the project CLAUDE.md short (project one: ~15 KB max); details go in `docs/`.
- Keep a `SUIVI.md` / state file rewritten (not appended) after each step: current state, what did not work,
  exact next step.
- Search (Grep/Glob) before reading; read only the useful part of a file; cut long outputs.
- Start a new conversation (with a hand-over note) rather than switching model or effort in a long one.
