# Handoff: Claude configuration standardization and audit

Paste everything below the line into a Claude Code session started in the folder where
`claude-setup/` was unzipped. The session should have web search available. Expect it to
take a while; it is meant to run in phases with a checkpoint after each one.

---

I'm Wyatt, IT/DevOps at DLZ Corp (AEC firm, ~30 offices, hybrid AD/Exchange/Entra/M365,
NIST 800-171/CMMC exposure). Claude Code is my primary surface for both coding and
non-coding work; claude.ai and Cowork are for one-offs. My main languages are PowerShell
(scripts must declare a target: Windows PowerShell 5.1, PowerShell 7.6, or Both), Python,
and C#/.NET. I also do a lot that isn't code: M365/Entra admin, licensing analysis,
compliance docs, leadership write-ups.

A chat session already researched current Claude Code practices and produced a draft
layered setup in `./claude-setup/`. Read `claude-setup/README.md` first; it maps every
file to where it installs and when it loads. The drafts replace a single year-old
"coding preferences" document that is now at `claude-setup/old-preferences.md` if present,
otherwise I'll paste it when you ask.

Your job has four phases. Stop at the end of each and show me what you found or changed
before moving on. Use plan mode for anything that modifies files. Ask with AskUserQuestion
when a choice is mine to make; don't ask about things you can check yourself. No emojis
anywhere. Show evidence (command output) for every check you claim to have run.

## Phase 0: Inventory

1. Read every file in `claude-setup/`.
2. Inventory what already exists on this machine and report it as a table before changing
   anything: `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/skills/`,
   `~/.claude/agents/`, `~/.claude/settings.json` (hooks, permissions, plugins, MCP
   servers, env), `~/.claude/output-styles/`, and the auto memory index via `/memory`.
   Note the Claude Code version with `claude --version`.
3. Check whether any existing repo already versions Claude config (my powershell-profile
   repo is the likely place; ask me for the path). Report what you find; it moves to the
   new repo in Phase 1.
4. For each existing item, classify it: keep as-is, fold into the new standardized file,
   or retire. My intent is to replace what's there with standardized versions, so nothing
   survives in its old form, but nothing I wrote on purpose should be lost either.

## Phase 1: Standardize and install

1. Back up the current `~/.claude/` to `~/.claude.bak-<date>/`.
2. Merge anything worth keeping from Phase 0 into the drafts, then install:
   `claude-setup/home/.claude/*` to `~/.claude/`. Keep each file within the size guidance
   in the README (CLAUDE.md under 60 lines, rules under 60, skills under 500).
3. Create a dedicated repo for my Claude config (I'll give you the name and remote;
   default `claude-config`). It holds `CLAUDE.md`, `rules/`, `skills/`, the shareable
   parts of `settings.json`, the repo templates, and this audit. Propose how it maps onto
   `~/.claude/`: an install script that copies files, or symlinks. Explain the Windows
   symlink constraint (Developer Mode or admin) and recommend one. Wait for my choice,
   then set it up, add a README with the install steps, and make the first commit.
   Anything machine-specific or secret (API keys, local paths, auto memory) stays out
   of the repo; add a `.gitignore` for it.
4. Put the claude.ai preferences text somewhere I can paste it from, and remind me to do
   that step manually; you can't.

## Phase 2: Verify

1. `/context` in a fresh session: confirm `~/.claude/CLAUDE.md` is listed. Open a `.ps1`
   and run `/context` again: confirm `rules/powershell.md` loaded and `python.md` and
   `dotnet.md` did not. Repeat for `.py` and `.cs`.
2. Run `/doctor prompt-audit`. Apply its proposed edits only after showing me the diff.
3. Test the three skills (`spec`, `ps-script`, `it-writeup`) using the skill-creator
   skill's full loop: three realistic prompts each, run with-skill and without-skill
   baselines, generate the eval viewer for me to review, then revise. After I'm happy,
   run the description optimizer so they trigger when they should. Realistic prompts for
   me look like: "write me something that finds stale computer objects in AD and disables
   them", "I need a one-pager for the CIO on whether we renew Copilot seats", "let's
   build a tool that reconciles MetaField users against AD".
4. Check `/memory` auto memory for anything that duplicates or contradicts the new files.
   Dedupe in favor of the file.

## Phase 3: Full audit

This is the part I care most about. Produce `AUDIT.md` with findings ranked by impact,
each with: what's wrong or missing, why it matters, the recommendation, and effort
(hours). Research with web search where the answer depends on current practice; cite
sources. Cover at least:

- **Instruction quality.** Are the installed files concrete and testable, consistent with
  each other, free of things Claude already does by default, and free of "never do X"
  rules that should be hooks or permissions instead?
- **Hooks.** What should run deterministically that I'm currently relying on instructions
  for? Candidates: PSScriptAnalyzer after every `.ps1` edit, `ruff` after `.py` edits,
  `dotnet build` after `.cs` edits, a PreToolUse block on writes to anything matching
  secrets or credential patterns, a Stop hook that refuses to end a turn with failing
  tests. Propose `settings.json` entries; install only what I approve.
- **Permissions and sandbox.** Review the permission mode and allowlists for a machine
  that touches production AD/Exchange/Entra. Recommend a safe default and what to
  allowlist so I'm not clicking through every `Get-*`.
- **Plugins and MCP.** Which code-intelligence plugins fit my languages? Which MCP servers
  do I have configured, are any stale, and what's missing for my daily work (Atlassian,
  Microsoft 365, GitHub)?
- **Repo hygiene and AGENTS.md.** Explain AGENTS.md to me in a few sentences, then pick
  one of my active repos (PSADT-Templates, the .NET lifecycle suite, or the Samsara
  trips function; ask which) and walk me through writing its AGENTS.md from the template
  in `claude-setup/repo-templates/`. Confirm Claude Code reads it with `/memory`.
- **My existing code against the new conventions.** Sample three recent scripts or
  projects and report where they diverge from the rules files. I want to know what I'm
  doing wrong, not just what the rules say.
- **Workflow.** Based on what you see in my repos and session history, am I using plan
  mode, specs, subagents, worktrees, and `/clear` where I should? What's the one habit
  change with the biggest payoff?
- **Trends.** What's changed in the last six months in Claude Code and in AI-assisted
  development generally that the drafts don't reflect? Be specific and sourced; skip
  anything that's just a product announcement with no bearing on my work.
- **Org admin angle.** I'm the Claude Team admin at DLZ. Note anything here that should
  become a managed CLAUDE.md or managed setting for the whole org versus staying
  personal. Don't deploy anything org-wide; just flag it.

## Phase 4: Deliver

1. `AUDIT.md` committed to the claude-config repo.
2. A short list of decisions I still owe you, with your recommendation for each.
3. A one-paragraph summary of what changed on this machine and how to roll it back from
   the backup.
