# Claude setup for Wyatt

This folder replaces the single "Claude Coding Preferences" document with a layered setup.
Each file loads in a different place and at a different cost, so general instructions stay
short and language conventions only load when relevant. Install order below; nothing here
depends on anything else, so you can adopt pieces one at a time.

## What goes where

| File | Install to | Loads when |
|---|---|---|
| `claude-ai-preferences.md` | claude.ai > Settings > Profile > preferences field | Every claude.ai chat |
| `home/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Every Claude Code and Cowork session |
| `home/.claude/rules/powershell.md` | `~/.claude/rules/powershell.md` | Only when a .ps1/.psm1/.psd1 file is read or edited |
| `home/.claude/rules/python.md` | `~/.claude/rules/python.md` | Only when a .py or pyproject.toml is touched |
| `home/.claude/rules/dotnet.md` | `~/.claude/rules/dotnet.md` | Only when .cs/.razor/.csproj/.sln is touched |
| `home/.claude/skills/spec/` | `~/.claude/skills/spec/` | `/spec` or when a non-trivial build request comes in |
| `home/.claude/skills/ps-script/` | `~/.claude/skills/ps-script/` | `/ps-script` or when asked for a PowerShell script |
| `home/.claude/skills/it-writeup/` | `~/.claude/skills/it-writeup/` | `/it-writeup` or when asked for a memo/analysis/recommendation |
| `repo-templates/AGENTS.md` | Root of each repo | Read by Claude Code, Copilot, Cursor, Codex |
| `repo-templates/CLAUDE.md` | Root of each repo, next to AGENTS.md | Imports AGENTS.md and adds Claude-only notes |

## Install

```powershell
# From the folder containing this README
Copy-Item -Recurse -Force .\home\.claude\* "$HOME\.claude\"
```

Then paste `claude-ai-preferences.md` into claude.ai settings. In a Claude Code session,
run `/context` to confirm `~/.claude/CLAUDE.md` is listed under Memory files, then open a
`.ps1` file and run `/context` again to confirm the PowerShell rule loaded.

## Maintenance

- Run `/doctor prompt-audit` every few months. It reports stale or conflicting instructions
  across CLAUDE.md, rules, and skills without changing anything.
- When Claude makes the same mistake twice, add one concrete line to the relevant file.
  When Claude already does something right, delete the line that tells it to.
- Keep `~/.claude/CLAUDE.md` under 60 lines and each rule under 60 lines. Anything
  procedural (a multi-step workflow) belongs in a skill, not a rule.
- Auto memory is on by default in Claude Code and records your corrections per repo.
  Check `/memory` before adding a rule; it may already be captured.
- Version bumps to watch: .NET 11 (Nov 2026), Python 3.15 (Oct 2026), PowerShell 7.4 LTS
  end of support (Nov 2026).
