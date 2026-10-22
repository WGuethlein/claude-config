# Phase 4 summary, 2026-10-22

This closes out the configuration standardization from `docs/HANDOFF.md`. It lists the decisions and
manual steps Wyatt still owes, each with a recommendation, and explains what changed on this machine and
how to roll it back. Findings and evidence are in `docs/AUDIT.md`.

## Decisions and steps still owed

Ordered by impact. A "Rec" line gives the recommendation.

### Do soon (security and correctness)

1. **Update the terminal CLI.**
   - `claude --version` still reports 2.1.235 (checked 2026-10-22), and the updater has failed since Aug 20.
   - Rec: run `claude update`. If it fails, reinstall with the native installer and keep the error output.
2. **Prune credential-bearing allow rules.**
   - 13 rules mention auth, token, password, or secret terms in `.claude/settings.local.json` for InternalApi, ProjectSetupFormBot, and SigninService.
   - Rec: delete those rules and rotate any token that is real. The reviewed user-level allowlist now covers reads.
3. **Org-wide: disable bypassPermissions mode** in the admin console's server-managed settings (Organization settings > Claude Code).
   - Rec: yes. No DLZ user needs to skip every prompt.
   - Flagged only; nothing org-wide was deployed.
4. **Lint-after-edit hook** (proposal C), not chosen in Phase 3.
   - Rec: install it. It is the single biggest fix for the 42% verification rate, and it costs nothing per session.
   - First install PSScriptAnalyzer for pwsh 7: `Install-PSResource PSScriptAnalyzer`.
5. **Secret-file write block** (proposal D), not chosen in Phase 3.
   - Rec: install it. It's about 40 lines and turns the "no secrets" rule into a check.

### Do when convenient (noise and quality)

6. **Plugins.**
   - Rec: disable autoharness: its MCP server fails, its hooks use Unix syntax, and it drops folders in working directories.
   - Rec: turn off the marketing, product-management, and zoom plugins for your account in claude.ai.
   - Rec: keep superpowers for now. Disable it per repo if brainstorming keeps gating simple tasks.
7. **Code-intelligence plugins.**
   - Rec: install `csharp-lsp` (needs `csharp-ls`) and `pyright-lsp` (needs `pyright-langserver`).
   - There is no official PowerShell equivalent.
8. **Rule changes suggested by your own code.**
   - Rec: adopt all four:
     - map `-WhatIf` to a tool's native dry run
     - a "scheduled and CLI apps" line in `dotnet.md` (per-failure exit codes, overlap lock)
     - a side-effect test for any dry-run or preview mode
     - StrictMode and `#Requires` at the module root, not in each dot-sourced function file
9. **Code clean-up, each its own task in its own repo.**
   - Rec, in this order:
     1. WyattTools: StrictMode, `$ErrorActionPreference = 'Stop'`, `#Requires`, and transcripts on mutating commands.
     2. InternalApi: move EF Core out of Core, add a `Directory.Build.props` with `TreatWarningsAsErrors`, and clean up the history comments ("harness", "Phase 2").
     3. Samsara: `pyproject.toml` with ruff and pytest, and split `handler()`.
10. **Add the external-forwarding report to WyattTools.**
    - Rec: yes, as a read-only function. The eval output in `skill-evals/` is a good starting point.
11. **Re-test `it-writeup`.**
    - Its output changed to .docx built on the DLZ templates.
    - Rec: one static-only re-run before you rely on it for a CIO memo.
12. **Tune the skill descriptions.**
    - Run skill-creator's description optimizer on `spec`, `ps-script`, and `it-writeup`: a few hundred calls per skill.
    - Rec: run it when you have budget. It is the lever for skills triggering on their own.
13. **AGENTS.md: deferred.**
    - Rec: start with Dayforce, your busiest repo with the most corrections.
14. **Clean-up.**
    - Rec: delete `C:\Projects\claude-config\.rulecheck` (two test files) and `C:\Projects\claude-config\claude-setup` (the extracted handoff copy, already preserved in `docs/` and `home/`). Both still exist as of 2026-10-22.
15. **File edits stay ungated.**
    - Claude's edits inside a project are approved by auto mode. Commands that change state prompt.
    - Rec: keep it this way. Add `Edit` and `Write` ask rules only if you want every edit approved.

## What changed on this machine and how to roll it back

**What changed**
- `~/.claude` now points at `C:\Projects\claude-config` (github.com/WGuethlein/claude-config):
  - `rules`, `agents`, `hooks`, `evals`, and six owned skills are directory junctions into `home/`
  - `~/.claude/CLAUDE.md` is a one-line import of `home/CLAUDE.md`
- `install.ps1` merged the repo's permissions, hooks, plugins, and marketplaces into the local `settings.json`. The new permissions ask on state-changing commands, deny AD writes, and disable bypass mode.
- Retired from `~/.claude`, now in `archive/`: the chief-operator CLAUDE.md, `coding-standards.md`, three agents, two skills, and risk guard v1.
- Outside the repo, the `find-skills` description in `~/.agents/skills/find-skills/SKILL.md` was edited.

**How to roll it back**
A full copy of `~/.claude` from before any change is at `C:\Users\wguethlein\.claude.bak-2026-10-20` (3,337 of 3,337 files, robocopy-verified). Items the installer replaced were moved, not deleted, to `C:\Users\wguethlein\.claude.pre-link-20261020-124250`, and each settings merge left a `settings.json.bak-<timestamp>` beside the live file.

1. Remove the junctions with `cmd /c rmdir`, never `Remove-Item -Recurse`, which follows the junction into the repo:
   - `rules`, `agents`, `hooks`, and `evals`
   - the six skill junctions: `spec`, `ps-script`, `it-writeup`, `powershell-cmdlet-verifier`, `pii-sweep`, `devils-advocate`
2. Delete the stub `CLAUDE.md`.
3. Copy the backup back over `~/.claude` with robocopy.

**Partial rollbacks**
- For a single repo file, `git revert` the relevant commit and re-run `install.ps1`.
- The `find-skills` edit is the one change the backup does not cover, because it lives under `~/.agents`. Its original description is quoted as hunk 6 in `docs/prompt-audit-2026-10-20.md`.
