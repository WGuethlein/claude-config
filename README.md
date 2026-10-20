# claude-config

Wyatt's Claude Code configuration, versioned. `install.ps1` points `~/.claude` at this repo so edits
here take effect immediately and edits made through `~/.claude` land in git. Machine-specific state
(credentials, auto memory, transcripts, the operations log, local settings) never enters the repo.

## Layout

| Repo path | Installs as | Method | Loads when |
|---|---|---|---|
| `home/CLAUDE.md` | `~/.claude/CLAUDE.md` | One-line `@import` stub | Every session |
| `home/rules/` | `~/.claude/rules/` | Junction | Path-scoped: `powershell.md` on .ps1/.psm1/.psd1, `python.md` on .py/pyproject.toml, `dotnet.md` on .cs/.razor/.csproj/.sln |
| `home/agents/` | `~/.claude/agents/` | Junction | `builder`, `qa-engineer`, `adversarial-critic` |
| `home/hooks/` | `~/.claude/hooks/` | Junction | Run by the hook entries in settings |
| `home/evals/` | `~/.claude/evals/` | Junction | Run on demand by `qa-engineer` |
| `home/skills/<name>/` | `~/.claude/skills/<name>/` | Junction per skill | On trigger or `/<name>` |
| `settings/settings.shared.json` | Keys merged into `~/.claude/settings.json` | Merge | `hooks`, `enabledPlugins`, `extraKnownMarketplaces` |
| `repo-templates/` | Root of a project repo | Copy by hand | `AGENTS.md` plus a `CLAUDE.md` that imports it |
| `claude-ai-preferences.md` | claude.ai > Settings > Profile | Paste by hand | Every claude.ai chat |
| `docs/` | Not installed | | Handoff, old preferences, audit |
| `archive/` | Not installed | | Retired config, kept verbatim |

Why junctions and not symlinks: Windows symlinks need admin rights or Developer Mode, and this
machine has neither. Directory junctions need no privilege on a local NTFS volume. A single file
cannot be junctioned, so `CLAUDE.md` is an `@import` stub instead.

## Install

```powershell
git clone https://github.com/WGuethlein/claude-config.git C:\Projects\claude-config
cd C:\Projects\claude-config
.\install.ps1 -WhatIf     # preview
.\install.ps1 -Verbose    # apply
```

Re-running it is safe: correct links are skipped, and it prints `No changes` when everything matches.
Anything it replaces is moved, never deleted, to `~/.claude.pre-link-<timestamp>/`. Before it changes
`settings.json`, it writes a backup to `settings.json.bak-<timestamp>`.

To verify, start a fresh session and run `/context`. `~/.claude/CLAUDE.md` and the imported
`home/CLAUDE.md` should both be listed under memory files.

## Not in this repo

- Third-party skills, kept as their existing junctions to `~/.agents/skills/`:
  - `find-skills`
  - `security-audit`
  - `ui-ux-pro-max`
- Plugins install from the marketplaces listed in `settings.shared.json`.
- `~/.claude/OPERATIONS_LOG.md`. It records incidents that involve real data, so it stays local.

## Uninstall or roll back

Delete the junctions and the stub. Then restore from `~/.claude.pre-link-<timestamp>/` or from the
full backup at `~/.claude.bak-2026-10-20/`. Deleting a junction does not delete the repo files it
points to; use `(Get-Item <path>).Delete()` or `cmd /c rmdir <path>`, never `Remove-Item -Recurse`.
