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

## Scheduled routines

- A routine run is a real local session, started in the project folder where the routine was created: create it from that project's conversation. The scheduling tool has no setting for folder or permissions, and runs are listed under the app's scheduled tasks (archive them like any session).
- Never create a routine in auto-permission mode without the user's explicit agreement. Keep routines read-and-report only; use the OS scheduler for anything that acts.

## UI mockups and end of subject
- First mockup or major redesign of a screen: do it with the strongest model at high effort. A weaker model must not
  start it: it writes the brief in the state file and stops. If a mockup was made on a weaker model anyway, say so at
  the top of the report and propose a stronger-model pass before coding.
- Visual work (mockups, UI, CSS) defaults to the strongest Claude model at max effort: it is cheaper in quota and reliable. Codex only takes it when the user explicitly asks, and then through `cx.sh visuel` (top model, high effort, write access), never the cheap `executant` and never the read-only `architecte`.
- Light change on a validated mockup: the mid model does it, then the hard role (`architecte`) reviews the captures.
  The report always shows: before/after captures side by side, one line per change, the reviewer's verdict (2-3 lines),
  remaining gaps. Without these, it is not "done".
- End of subject (state file clean) and the next request is of another nature: before starting, say "new conversation
  advised, model/effort: X" and wait for the user's choice. A detail to fix on the current subject is finished in the
  same conversation. A linked subject that needs earlier context is still a new conversation: the state file carries it.
- Handover point inside a long job (added 2026-10-26): a finished batch is a clean handover point if the state file is rewritten clean (decisions in force, list of validated items, the why of oral decisions, next step) AND a non-regression script is green (rebuild + checks + comparison with validated references). Then say "clean handover point, new conversation advised" and let the user choose; red script or incomplete state file = stay. If the user says he is away, do not ask to change conversation. Code details are not in the state file: re-read them on demand.
- Changing model or effort mid-conversation rebuilds the whole cache (about 2x the context): do it at a subject
  boundary while the context is small.

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
