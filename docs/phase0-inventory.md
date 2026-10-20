# Phase 0 inventory, 2026-10-20

What was in `~/.claude` before Phase 1, how each item was classified, and the usage evidence behind
those choices. The input for Phase 3 (AUDIT.md). Claude Code version: 2.1.235.

## Inventory and disposition

| Item | Found | Disposition |
|---|---|---|
| `CLAUDE.md` (42 lines, "Chief Operator") | Model routing table, evidence rule, delegation loop, ops log pointer | Folded into `home/CLAUDE.md`: evidence rule, hook rule, failure log, compaction fields. Routing table dropped. Original in `archive/`. |
| `rules/coding-standards.md` | Not path-scoped, so it loaded in every session | Retired; superseded by the three path-scoped rules |
| Agents: `builder`, `qa-engineer` | `model: sonnet` | Kept |
| Agent: `adversarial-critic` | `model: claude-fable-5` (legacy) | Kept, model changed to the `fable` alias |
| Agents: `chief-operator`, `research-scout`, `system-fixer` | Duplicate the main session, Explore/claude-code-guide, and `builder` | Retired to `archive/` |
| Skills: `powershell-cmdlet-verifier`, `pii-sweep`, `devils-advocate` | Written by Wyatt | Kept; `ps-script` now calls the verifier |
| Skills: `researcher`, `subagent-driven-development` | The first only dispatched to research-scout; the second has the same name as a superpowers skill | Retired to `archive/` |
| Skills: `find-skills`, `security-audit`, `ui-ux-pro-max` | Junctions to `~/.agents/skills` | Left in place, not versioned |
| Hooks: risk-guard, evidence-logger, precompact-handoff, session-logger | PowerShell, wired in settings.json | Kept, unchanged; review in Phase 3 |
| `evals/` (8 plus README) | One per repeated failure | Kept; references to retired agents repointed |
| `OPERATIONS_LOG.md` | About 15 entries, some describing real PII incidents | Local only, gitignored |
| Plugins | superpowers, autoharness, claude-code-setup, nopus | Unchanged; review in Phase 3 |
| MCP servers in `~/.claude.json` | None; connectors come from claude.ai | Phase 3 |
| `output-styles/`, `commands/` | Empty | None |
| Auto memory | 19 project folders, 78 files | Dedupe in Phase 2 |
| Existing config repo | `powershell-profile` does not version Claude config (its `.gitignore` excludes `.claude/`) | Nothing to move |

## Usage evidence (723 transcripts, 2026-07 to 2026-10)

Subagent dispatches:

| Agent | Dispatches |
|---|---|
| `builder` | 321 |
| `general-purpose` | 241 |
| `adversarial-critic` | 69 |
| `qa-engineer` | 32 |
| `research-scout` | 29 |
| `Explore` | 26 |
| `Plan` | 4 |
| `system-fixer` | 1 |

Skill invocations:

- superpowers: brainstorming 13, writing-plans 7, subagent-driven-development 7, systematic-debugging 6.
- Not on disk, probably claude.ai org skills: `dlz-environment` 10, `script-scaffolder` 2.
- Wyatt's own: `powershell-cmdlet-verifier` 4, `pii-sweep` 4, `devils-advocate` 3, local `subagent-driven-development` 2, `researcher` 1.

Risk guard, October: 3 DENY and 24 ASK. All three denials were false positives:

- a filename `Remove-ADGroup.ps1` inside a loop
- a `Get-Command -Name Remove-ADGroup` lookup
- an append to OPERATIONS_LOG.md whose text named the cmdlet

The guard matches strings, not intent.

## Corrections made during Phase 1

- The three "symlinked" skills are directory junctions. Real symlinks failed with "Administrator
  privilege required", and Developer Mode is off. The install uses junctions plus a CLAUDE.md import stub.
- The `ps-script` draft pointed at `/mnt/user-data/outputs/`, a claude.ai sandbox path. Fixed.
