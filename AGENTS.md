# AGENTS.md - shared working rules for Codex and Claude Code

Install: copy this file to the root of your project (or to `~/.codex/AGENTS.md` for all Codex sessions).
- Codex reads `AGENTS.md` natively.
- Claude Code reads `CLAUDE.md`: copy the one-line `CLAUDE.md` of this repo next to it (it only contains `@AGENTS.md`).
- Keep it short: it is re-read on every session. Details go in `docs/`.
- Optional global Claude settings (model, effort, agents): see `docs/` and `agents/`.

## Working rules
1. Before writing: read the project README/AGENTS.md and the files next to the ones you change; follow their conventions
   (names, imports, style). Do not reinvent a utility that already exists.
2. Change only what is asked. Minimal diff: no renaming, no refactor, no reformatting outside the request.
3. Never say "done" without executed proof. Run the code and the tests (use the direct command: the venv's python +
   pytest, not a wrapper). If nothing can be run, say so.
4. Check integration: callers in other modules, imports, edge cases, empty and error states.
5. Re-read the request at the end and tick each requirement one by one in your final answer. A missed requirement means
   the task is not finished.
6. No workaround: if making a test pass needs an exception or special case, or two tests (or a test and the doc)
   contradict each other, do NOT code around it. Leave the test red, report the contradiction, ask for a decision.
7. Final answer, short: what is done, proof (commands + results), what is NOT verified, what remains.
8. An answer without any modified file is a failure (for implementation tasks).
9. Keep a state file (`SUIVI.md` / `STATE.md`) rewritten, not appended, after each step: current state, what did not
   work, exact next step.

## Agent roles
- Light (Haiku / Codex `lecteur`): search, list, count, read many files, run a command and report its output.
- Mid (Sonnet / Codex `executant`): write already-designed code, targeted fixes, tests.
- Hard (Opus `architecte` / Codex `enqueteur`): design, hard bugs, contradictions. Use sparingly.
- The main thread designs, decides and verifies; it does not do bulk reading, writing or testing itself
  (3+ files or ~300 lines to read, code > ~30 lines, long test runs -> delegate).
- An agent that hits the same error 2-3 times stops and reports what it tried; it never loops.
- Call the hard role when: a test still fails after 2 fixes; you are about to write a workaround; two tests contradict;
  your report would contain "serious doubts" / "not verified"; no progress after 2 checkpoints.

## Recipe: Codex implements, Claude verifies once
Only if `codex` is installed, logged in and has quota; otherwise use the Claude-only pipeline.
1. Codex implements ONCE (`codex/cx.sh executant "<brief>" <dir>`). Linear chain: no back-and-forth.
2. Claude verifies ONCE: run the tests, read the diff, accept only what is proven. Never accept Codex output as is.
3. The brief must give the direct test command; say "adapt existing tests that the plan contradicts to the new
   contract, without weakening them, and list them"; say "an answer without any modified file is a failure".
4. Hard multi-file bug hunts: `cx.sh enqueteur`, then one Claude verification.
