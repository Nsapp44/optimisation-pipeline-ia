# INSTALL.md - guide for a Claude Code agent

You are Claude Code. The user cloned this repository and opened you INSIDE the clone, then asked: "Read INSTALL.md and do it."
Follow the numbered steps below, in order. Talk to the user in the language they use.

Windows/PowerShell and macOS/Linux supported; this procedure has been written for Claude Code to execute; test it on a throwaway profile first (CLAUDE_CONFIG_DIR=<empty dir>).

It has not been tested end to end. If a step does not behave as described, stop, tell the user what you saw, and do not improvise destructive workarounds.

Notation: `REPO` = the current working directory (this clone). `CFG` = the Claude config directory: `$CLAUDE_CONFIG_DIR` if that environment variable is set, otherwise `~/.claude` (Windows: `%USERPROFILE%\.claude`). Wherever this file says `~/.claude`, use `CFG`.

## What this repository installs

- `agents/*.md`: sub-agent definitions (architecte, chasseur-erreurs, chercheur-web, executant, executant-ui, lecteur, securite-web, seo, testeur).
- `skills/*/`: skills (blender-anim-web, menage-claude-md, motion-tiktok, passation, verif-pixel, verif-responsive-web, web-design-guidelines).
- `hooks/*.py`: six small Python hooks (below).
- `claude/settings.modele.json`: a settings template that registers the hooks, plus some PROPOSED preferences.
- `claude/CLAUDE.md`: an optional global instruction file (written by the repository author; the texts are partly in French).

## What each hook does

- `claude_md_taille` (UserPromptSubmit): warns Claude when the project's `CLAUDE.md` (in the current directory, or `.claude/CLAUDE.md`) is larger than 15 KB, and asks it to run the `menage-claude-md` skill at the end of the current task.
- `suivi_taille` (UserPromptSubmit): warns once per conversation when the project's `SUIVI.md` (or `docs/SUIVI.md`) is larger than 8 KB.
- `pause_longue` (UserPromptSubmit): after a pause of more than 1 hour in a conversation with more than ~80k tokens of context, the prompt cache is lost; the hook blocks the first message you type and asks you to confirm (sending the message again lets it through). Automated/scheduled messages, /compact, /clear and "passation" messages are never blocked.
- `boucle_compact` (UserPromptSubmit): detects compaction loops (two compactions less than 15 minutes apart) and tells Claude to write the handoff notes and continue in a clean conversation (skill `passation`). It never blocks your message.
- `protege_fichiers` (PreToolUse on Write/Edit/MultiEdit/Bash): denies writing to `.env` files (`.env.example`/`.sample`/`.template` are allowed) and asks for confirmation before a recursive delete (`rm -r`, `Remove-Item -Recurse`, `rmdir /s`, `del /s`, `git clean -f`).
- `conso_5h` (status line, optional): shows 5-hour / 7-day usage and context percentage in the status bar (only Pro/Max plans send rate-limit data); it also writes `CFG/bureau_conso.json`. No network access.

Note: `pause_longue` and `boucle_compact` write a small state JSON file next to the hook (`CFG/hooks/*_etat.json`); `suivi_taille` writes a flag file in the temp directory.

## Step 0 - Safety rules (read before doing anything)

1. Everything you are about to touch is backed up first: create `CFG/backup-<YYYY-MM-DD_HHMM>/` and copy into it (keeping relative paths) every file you will modify or overwrite: `settings.json`, `CLAUDE.md`, and any conflicting agent/skill/hook. If a file does not exist, there is nothing to back up. Tell the user the backup path.
2. NEVER overwrite an existing file without first showing the user a diff (or the two versions) and getting their explicit agreement. Use the `AskUserQuestion` tool if available, otherwise ask in plain text and wait for the answer.
3. Install nothing except the content of THIS repository. No package installs, no downloads, no network calls, no changes outside `CFG` (and the backup folder).
4. If anything is unclear or fails twice in the same way, stop and report to the user.

## Step 1 - Diagnostic

Collect and report (briefly):

1. OS and shell (Windows/PowerShell, macOS, Linux).
2. Python interpreter. Detect it with `where python` / `where python3` (Windows) or `which python3` / `which python` (macOS/Linux). On Windows ignore the Microsoft Store stub (`...\WindowsApps\python.exe` that only opens the Store): verify with `<candidate> --version` that it really runs. Python 3.8+ is enough (standard library only). Record the ABSOLUTE path (call it `<python>`) and write that path in the hook commands; never hard-code a path of your own or rely on `PATH` at hook run time.
   If no working Python is found: tell the user the hooks and the status line are optional, skip steps 4 (hooks part) and the hook checks of step 6, and install only agents, skills and (optionally) CLAUDE.md.
3. Claude Code version (`claude --version`).
4. What already exists in `CFG`: list `agents/`, `skills/`, `hooks/`, whether `settings.json` exists (and which top-level keys, which hooks, whether `statusLine` is set, whether `permissions` exist), whether `CLAUDE.md` exists and its size.
5. `<home>` = the user's home directory as an absolute path (on Windows use forward slashes in JSON, e.g. `C:/Users/name`). If `CLAUDE_CONFIG_DIR` is set, use `CFG`'s parent logic instead: the hook commands must point to `CFG/hooks/...`, so replace `<home>/.claude` by `CFG` in the template.

## Step 2 - Compare with what exists

For every file in `REPO/agents/*.md`, `REPO/skills/*/` (compare each file inside), `REPO/hooks/*.py`, classify against `CFG`:

- ADD: does not exist in `CFG`.
- IDENTICAL: exists with the same content (compare bytes; ignore CRLF vs LF differences only if you say so).
- CONFLICT: same name, different content.

Also note: `REPO/skills/motion-tiktok/SKILL.md` has no YAML frontmatter (no `name:`/`description:` block), so Claude Code will probably not load it as a skill. Tell the user and ask whether to copy it anyway (default: skip it).

Give the user a short summary (counts and the list of conflicts) before copying anything.

## Step 3 - Copy the files

1. Create `CFG/agents`, `CFG/skills`, `CFG/hooks` if missing.
2. Copy `REPO/agents/*.md` to `CFG/agents/`, each `REPO/skills/<name>/` folder (whole folder) to `CFG/skills/<name>/`, and `REPO/hooks/*.py` to `CFG/hooks/`. Keep the files as they are (LF line endings, do not reformat).
3. ADD and IDENTICAL items: copy / skip silently. For each CONFLICT: show the diff and propose three choices: keep the existing one, replace it (the old one is already in the backup), or install the repository version under another name (agents/skills: change the `name:` too, hooks: add a `_repo` suffix and register that name in step 4). Apply the user's choice per conflict.
4. Do not copy `claude/`, `docs/`, `results/`, `assets/`, `codex/`, `AGENTS.md`, `CLAUDE.md` of the repo root: they are documentation or project files, not configuration.

## Step 4 - Register the hooks in settings.json

Target file: `CFG/settings.json`.

1. Back it up (step 0) if it exists. If it does not exist, start from `{}`.
2. READ it fully and parse it as JSON. If it does not parse (comments, trailing commas...), stop and ask the user; do not try to rewrite it blindly.
3. Read `REPO/claude/settings.modele.json`.
4. MERGE, never replace:
   - Hooks. Take the entries of `hooks.UserPromptSubmit` (claude_md_taille, suivi_taille, pause_longue, boucle_compact) and `hooks.PreToolUse` (protege_fichiers, matcher `Write|Edit|MultiEdit|Bash`) from the template. In each command, replace `<python>` by the absolute Python path found in step 1 and `<home>/.claude` by the real config path. Add them to the user's existing arrays (append a new group object, or append to the group with the same matcher). Do NOT add an entry whose command (same script name) is already registered. Keep every existing hook, group and permission of the user untouched.
   - Only register hooks whose script was actually copied (or kept) in step 3.
   - `statusLine` (conso_5h): ask the user whether they want it. Only if yes AND they do not already have a `statusLine`, add it (with `<python>`/`<home>` replaced). If they already have one, leave theirs and tell them.
   - Proposals. The template also contains `model`, `advisorModel`, `autoCompactWindow`, `workflowSizeGuideline`, `modelSettings`, `env` and `permissions.deny`. These are the author's PERSONAL preferences, not requirements. Show them to the user one by one with a one-line explanation (e.g. `permissions.deny` forbids the tools CronCreate, CronDelete, CronList, RemoteTrigger, PushNotification, NotebookEdit, EnterWorktree, ExitWorktree and the sub-agents general-purpose, claude and Plan; `model: sonnet` and `advisorModel: fable` select models; `autoCompactWindow: 160000` compacts the context at 160k tokens; `env` disables the 1M context and caps Bash output). Apply ONLY the ones the user accepts, and never overwrite a key the user already has with a different value without showing the diff and getting agreement. For `permissions.deny`, merge into the existing array without duplicates. Note that `advisorModel` may not exist on the user's plan or version; if unsure, recommend skipping it.
5. Write the merged JSON back (2-space indent, UTF-8 without BOM, LF).
6. VALIDATE: read the file again and parse it (e.g. `<python> -c "import json,sys;json.load(open(sys.argv[1],encoding='utf-8'));print('ok')" <path>`). If invalid, restore the backup immediately and report. Do not say you are done before this check passes.

## Step 5 - CLAUDE.md (optional, ask first)

1. Tell the user that `REPO/claude/CLAUDE.md` is the author's own global instruction file (~26 KB, partly French, with personal workflows). A long global CLAUDE.md costs tokens on every message, so they may prefer to skip it, or to read and trim it first.
2. If `CFG/CLAUDE.md` does not exist and the user agrees: copy it.
3. If it exists: propose to APPEND the repository file at the end of the existing one (with a heading line such as `## Imported from the repository` before it), never replace. Show the size before/after and get agreement. Backup first.
4. If the user declines, skip.

## Step 6 - Verification

1. For each installed hook, run it with a minimal input and check the exit code is 0, for example:
   - macOS/Linux: `echo '{}' | "<python>" "CFG/hooks/<hook>.py"; echo "exit=$?"`
   - PowerShell: `'{}' | & "<python>" "CFG\hooks\<hook>.py"; "exit=$LASTEXITCODE"`
   Do this for claude_md_taille, suivi_taille, pause_longue, boucle_compact, protege_fichiers and (if installed) conso_5h. Expected: exit code 0 and usually no output (conso_5h prints an empty line). Report any non-zero code with its error text.
2. List the installed agents (`CFG/agents/*.md`) and skills (`CFG/skills/*/SKILL.md`) and compare with the lists above.
3. Re-parse `CFG/settings.json` one last time.

## Step 7 - Finish

Tell the user:

1. To RESTART Claude Code (hooks, agents and skills are loaded at startup).
2. What changed: files added/replaced/skipped, settings keys merged, whether CLAUDE.md was touched.
3. Where the backup is: `CFG/backup-<date>/`.
4. How to undo: see "Uninstall" below.

## Manual fallback

If you (the user) prefer to do it by hand, or the agent cannot:

1. Copy `agents/*.md` into `~/.claude/agents/`, `skills/*` into `~/.claude/skills/`, `hooks/*.py` into `~/.claude/hooks/`.
2. Open `claude/settings.modele.json` and merge its `hooks` block into your `~/.claude/settings.json` by hand (keep your own hooks; add the entries under `UserPromptSubmit` and `PreToolUse`). Replace `<python>` with the absolute path of your Python (e.g. `C:/Python312/python.exe` or `/usr/bin/python3`) and `<home>` with your home directory (forward slashes). The other keys (`model`, `advisorModel`, `modelSettings`, `permissions.deny`, `statusLine`, `env`...) are optional proposals: take only what you want.
3. Check the JSON is valid (any JSON validator, or `python -c "import json;json.load(open('settings.json'))"`).
4. Optionally append `claude/CLAUDE.md` to `~/.claude/CLAUDE.md`.
5. Restart Claude Code.

## Uninstall

1. Quit Claude Code.
2. Restore the backup: copy the contents of `CFG/backup-<date>/` back over `CFG` (this restores your previous `settings.json`, `CLAUDE.md` and any replaced file).
3. Delete what was added: the agent files, skill folders and hook scripts listed in this repository from `CFG/agents`, `CFG/skills`, `CFG/hooks` (only those you did not have before), and the state files `CFG/hooks/boucle_compact_etat.json`, `CFG/hooks/pause_longue_etat.json`, `CFG/bureau_conso.json` if present.
4. If you did not back up settings.json for some reason, remove by hand the hook entries pointing to the six scripts, and the `statusLine` if it points to `conso_5h.py`.
5. Restart Claude Code.
