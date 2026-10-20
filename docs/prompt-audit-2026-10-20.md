# Prompt audit: Claude Code configuration (2026-10-20)

Audit of the instruction files that load into Claude Code sessions in this repository, checked for dated prompting patterns, stale facts, and conflicts. The proposed diff at the end is not applied.

## Assumptions

- **Scope.** `home/CLAUDE.md` (imported by `~/.claude/CLAUDE.md`), `home/agents/*.md`, `home/rules/*.md`, `home/skills/*/SKILL.md` and the verifier's reference files, `repo-templates/CLAUDE.md` and `repo-templates/AGENTS.md` (nested), and the git-ignored `claude-setup/` copy (nested). User-level skills `find-skills`, `security-audit` and `ui-ux-pro-max` (symlinked from `~/.agents/skills/`). Installed plugins superpowers 6.2.0, autoharness 0.3.3, claude-code-setup 1.0.0 and nopus 1.1.0, which are report-only.
- **Not present.** There is no project-root or `.claude/` CLAUDE.md, CLAUDE.local.md or AGENTS.md, no ancestor CLAUDE.md, and no managed-policy CLAUDE.md. `~/.claude/commands/` and `~/.claude/output-styles/` don't exist.
- **Not read.** Settings files, `.mcp.json`, `~/.claude.json`, credentials, `archive/` (not loaded), `docs/`.
- **All projects.** `~/.claude/agents`, `rules`, `hooks`, `evals` and most of `~/.claude/skills` are symlinks into `home/`. Every edit below to a `home/` file therefore **affects all projects**. The `find-skills` edit lives under `~/.agents` and also affects all projects.
- **Target model.** Claude Opus 5.5, the model running this audit. The subagents keep their own pinned aliases: `adversarial-critic` uses `fable`, and `builder` and `qa-engineer` use `sonnet`.
- **History.** The repository has two commits, and every line implicated in a conflict comes from the first one (`ec20ee5`), so git blame cannot say which side is newer.

## Summary

The core files (`home/CLAUDE.md`, the three language rules, `spec`, `it-writeup`, `ps-script`, `qa-engineer`) are in good shape for current models. They are plain-voiced, give reasons, and use emphasis only on real safety constraints. The highest-impact problems in the project are stale references and conflicts carried over from the archived `coding-standards.md`:

- `builder` points at a rules file that was moved to `archive/`.
- `powershell-cmdlet-verifier` points at a `dlz-environment` skill that doesn't exist.
- `devils-advocate` pins `claude-fable-5` while the critic agent uses the `fable` alias.
- Four files disagree on whether an unstated PowerShell target means "ask" or "assume 5.1". History can't settle this, so it is flagged for you to decide.

The largest issue overall is outside the project. The superpowers plugin injects `using-superpowers` into every session with "1% chance... YOU DO NOT HAVE A CHOICE" pressure. Its brainstorming hard gate competes with your plan-and-wait rule and the `spec` skill.

Counts: Group 1 (dated prompt text): 1. Group 2 (brittle configuration): 5 with edits, 6 flagged. Group 3 (tool descriptions): not applicable. Group 4 (request config): not applicable. The subagent roster check found nothing (builder, qa-engineer and adversarial-critic do distinct jobs). Plugins: report-only, see the last section.

## Findings

| # | Location | Evidence | Pattern | Why it no longer fits | Conf. | Action |
|---|---|---|---|---|---|---|
| 1 | `home/agents/builder.md:8-9` | "to the standards in ~/.claude/rules/coding-standards.md" | G2 volatile specifics | The file isn't in `home/rules/`. It now lives at `archive/rules/coding-standards.md`, which isn't installed, and its content was replaced by `powershell.md`, `python.md` and `dotnet.md`. | High | rewrite (hunk 1) |
| 2 | `home/skills/powershell-cmdlet-verifier/references/module-notes.md:3-6` | "General environment facts ... live in the `dlz-environment` skill" | G2 volatile specifics | No `dlz-environment` skill exists in `home/skills/`, `~/.claude/skills/` or `archive/`, so the pointer sends the model looking for nothing. | High | rewrite (hunk 2) |
| 3 | `home/skills/devils-advocate/SKILL.md:26-27` | "(subagent_type: adversarial-critic, model claude-fable-5, read-only)" | G2 history / pinned model name | The agent definition sets `model: fable`, which resolves to the current Fable (5.1). The skill pins the previous ID and contradicts the file that actually controls the model. | High | rewrite (hunk 3) |
| 4 | `home/skills/pii-sweep/SKILL.md:8-11` | "On this codebase it cleared a real SSN fragment and a real member ID twice" | G2 history narrative | This is a user-level skill that loads in every project, so "this codebase" is wrong almost everywhere. The incident is archaeology, but the failure mechanism is the real reason, and the rewrite keeps it. | Medium | rewrite (hunk 4) |
| 5 | `home/agents/adversarial-critic.md:24-26` | "Maximum ten findings; if you have more, the top ten only." | G1 1b/1f numeric output ceiling | A hard cap on a reviewer silently drops findings 11 and later, which is the opposite of the critic's job. Severity ordering already handles prioritization, and `devils-advocate` triages afterward. | Medium | rewrite (hunk 5) |
| 6 | `~/.agents/skills/find-skills/SKILL.md:3` (all projects) | description: "when they ask questions like 'how do I do X' ..." | G2 trigger enumeration | "How do I do X" covers most of your admin and scripting questions, and the description routes them toward a public skill marketplace. The rewrite names the intent ("find or install a skill"). Note that `npx skills update` may overwrite a local edit. | Medium | rewrite (hunk 6) |
| 7 | `home/rules/powershell.md:10`, `home/skills/ps-script/SKILL.md:10` vs `home/skills/powershell-cmdlet-verifier/SKILL.md:15-16`, `.../references/ps51-gotchas.md:3-4`, `home/agents/builder.md:17-18` | "If I didn't say which, ask before writing." / "If unknown, ask" vs "The default target is **Windows PowerShell 5.1** ... unless the user states otherwise" / "Windows PowerShell 5.1 is the default target" / "assume PowerShell 5.1 server-side unless stated" | G2 conflicting instruction files | The same point is ruled two ways. All lines come from one commit, so history can't order them. The "default 5.1" wording matches `archive/rules/coding-standards.md:18`, which suggests it is the older rule. You need to decide: should an unstated target mean ask (when writing) and assume 5.1 (when verifying existing code), or one rule everywhere? | n/a | flag |
| 8 | `home/agents/builder.md:24` vs `home/rules/powershell.md:14-19` | "standard header/variables/parameters/code structure" vs the layout list that puts `param()` (3) before variables (4) | G2 conflicting instruction files | The orders are opposite. Builder's phrasing matches `archive/rules/coding-standards.md:16`. History can't order the two lines. If you confirm `powershell.md` is current, the fix is "follow the layout in `~/.claude/rules/powershell.md`". | n/a | flag |
| 9 | `home/skills/devils-advocate/SKILL.md:36,45` vs `home/CLAUDE.md:34` | "a fix microtask (hand to a builder, don't silently patch)" / "Fixes flow back through builders" vs "Small edits stay in the main thread." | G2 conflicting instruction files | The skill sends every fix through `builder`, while CLAUDE.md keeps small edits in the main thread. Decide whether a review gate is meant to override that, and if so say so in the skill. | n/a | flag |
| 10 | `claude-setup/claude-setup/` (git-ignored) | Nested `home/.claude/CLAUDE.md`, `repo-templates/CLAUDE.md`, `AGENTS.md` | G2 conflicting instruction files | This is an extracted copy of the original handoff zip. Its CLAUDE.md is an older version of `home/CLAUDE.md`: no risk-guard rule, and "keep the main thread for decisions and implementation" instead of delegating builds. Nested files load when Claude reads files in that folder. The content is preserved in `docs/` and `home/`. Removing the folder is your call. | n/a | flag |
| 11 | `home/rules/powershell.md:11` | "Use `[System.Management.Automation.PSVersionHashTable]`-safe constructs" | unclear instruction (no row) | `PSVersionHashTable` is the type of `$PSVersionTable`. "PSVersionHashTable-safe" has no defined meaning, so the model has to guess. It probably means "guard 7-only features with a version check". | Low | flag |
| 12 | `repo-templates/CLAUDE.md:1-5`, `repo-templates/AGENTS.md` | "Use plan mode for changes under <sensitive path, e.g. src/Onboarding/>." | template loading as live config | When Claude edits files under `repo-templates/` in this repo, the placeholder instructions load as real ones. This is harmless today, but worth knowing. | Low | flag |
| 13 | `~/.agents/skills/find-skills/SKILL.md` Step 6 (all projects) | "`npx skills add <owner/repo@skill> -g -y` ... `-y` skips confirmation prompts" | security note (no row) | The step installs third-party skill code globally, with prompts skipped, into the layer that loads in every session. Given the CMMC exposure, consider requiring your confirmation and dropping `-y`. This is not a dated-prompt pattern, so no edit is proposed. | n/a | flag |

**No findings:** `home/CLAUDE.md`, `home/agents/qa-engineer.md`, `home/rules/python.md`, `home/rules/dotnet.md`, `home/skills/it-writeup`, `home/skills/spec`, `home/skills/ps-script` (apart from #7), and `ps51-gotchas.md` (apart from #7). Emphasis in these files is limited to destructive operations and verification, where the keep list protects it. `security-audit` and `ui-ux-pro-max` were checked with the signal greps and a read of their headers, not line by line. Their "do not" lines in `security-audit` carry reasons. "CRITICAL" in `ui-ux-pro-max` is a priority column in a data table, not pressure language.

## Installed plugins (report only, no edits proposed)

Paths are under `~/.claude/plugins/cache/`.

- **superpowers 6.2.0, highest impact.**
  - `skills/using-superpowers/SKILL.md:10-16` is injected into every session by the plugin's SessionStart hook, wrapped in `<EXTREMELY_IMPORTANT>`. Its 1% invoke threshold and "YOU DO NOT HAVE A CHOICE" are G1 pressure language. On a model that follows instructions literally, this over-triggers skills. Lines 20 and 39-50 ("Skill check comes BEFORE clarifying questions") put a skill ritual ahead of simple answers. (High)
  - `brainstorming/SKILL.md` has a HARD-GATE on "EVERY task", and using-superpowers says to brainstorm before plan mode. That is a second planning workflow competing with `home/CLAUDE.md:10` (plan only what you can't describe in one sentence) and the `spec` skill. (High)
  - `test-driven-development`, `systematic-debugging` and `verification-before-completion` have "Iron Law" rules, absolute language and "Delete it" instructions. These are G1/1c rigidity, and deleting code also cuts against your stop-before-deleting rule. (High/Medium)
  - Several skills open with "Announce at start: I'm using the...", which conflicts with "Concise". `receiving-code-review` uses check/cross glyphs that the model may mirror against your no-emoji rule. (Medium)
  - Mitigation in place: `using-superpowers:63` says user instructions take precedence. It sits below the louder block, though. If the plugin's behavior isn't wanted globally, disabling it per project is the lever. Editing it isn't, because updates overwrite edits.
- **autoharness 0.3.3.** `agents/reflector.md:5` and `agents/curator.md:5` pin `model: haiku` (Medium). `reflector.md:8,28` ("Capture liberally... when unsure, stage it") biases the agent toward creating skills that compete with your curated set (Medium).
- **claude-code-setup 1.0.0.** `skills/claude-automation-recommender/references/subagent-templates.md` bakes in tier labels ("Model: sonnet") and a dated MCP vendor table (Medium/Low).
- **nopus 1.1.0.** Clean. Both skills are `disable-model-invocation: true` and plainly worded.

## Proposed diff

These hunks are not applied, so you can take them one at a time. Hunks 1-5 edit `home/` files and affect all projects through the `~/.claude` symlinks. Hunk 6 edits a user-level file outside this repo and affects all projects.

```diff
--- a/home/agents/builder.md
+++ b/home/agents/builder.md
@@ -6,6 +6,6 @@
 ---
 
 You are the builder. You implement exactly what was dispatched, to the
-standards in ~/.claude/rules/coding-standards.md.
+conventions in the matching ~/.claude/rules/ file (powershell.md, python.md, dotnet.md).
 
 Mission: turn one bounded spec into working code with evidence.
```

```diff
--- a/home/skills/powershell-cmdlet-verifier/references/module-notes.md
+++ b/home/skills/powershell-cmdlet-verifier/references/module-notes.md
@@ -1,7 +1,6 @@
 # Module-Specific Verification Notes
 
-Modules that have caused version/edition/namespace failures in this environment. Read the
-relevant entry when a script touches one. General environment facts (hostnames, OUs, UPN
-formats) live in the `dlz-environment` skill — this file is only about *verification
-hazards*.
+Modules that have caused version/edition/namespace failures in this environment. Read the
+relevant entry when a script touches one. This file covers verification hazards only.
 
 ## ActiveDirectory (RSAT)
```

```diff
--- a/home/skills/devils-advocate/SKILL.md
+++ b/home/skills/devils-advocate/SKILL.md
@@ -23,9 +23,9 @@
    list + key files), the claim being made, the acceptance criterion, and any
    evidence already gathered (test output, build log). Vague input yields vague
    findings.
-2. **Dispatch `adversarial-critic`** (subagent_type: adversarial-critic, model
-   claude-fable-5, read-only). Prompt it to attack, not to agree. Ask specifically
+2. **Dispatch `adversarial-critic`** (subagent_type: adversarial-critic; read-only;
+   its model is set in its agent definition). Prompt it to attack, not to agree. Ask specifically
    for: where's the evidence, which file enforces this tomorrow, what edge case
    breaks it, what's unreviewed, what's bloat. Demand concrete pointers
    (file:line, log line), severity-ordered, no preamble.
```

```diff
--- a/home/skills/pii-sweep/SKILL.md
+++ b/home/skills/pii-sweep/SKILL.md
@@ -5,10 +5,10 @@
 
 # PII sweep
 
-A digit-shape grep alone is not a PII sweep. On this codebase it cleared a
-real SSN fragment and a real member ID twice, because it classified hits by
-whether they "looked invented" and never read the sentence sitting next to
-them. This skill checks the prose too.
+A digit-shape grep alone is not a PII sweep. It classifies hits by whether
+they "look invented" and never reads the sentence next to them, which is how
+real identifiers get cleared as fixtures. This skill checks the prose too.
 
 ## When to use
```

```diff
--- a/home/agents/adversarial-critic.md
+++ b/home/agents/adversarial-critic.md
@@ -22,5 +22,6 @@
 
 Output contract: numbered findings, each one line of claim and one line of
 evidence or its absence, ordered by severity. End with the single highest-value
-fix. Maximum ten findings; if you have more, the top ten only. No preamble.
+fix. If minor findings would bury the material ones, list the material ones and
+give a one-line count of what you left out. No preamble.
```

```diff
--- a/C:/Users/wguethlein/.agents/skills/find-skills/SKILL.md
+++ b/C:/Users/wguethlein/.agents/skills/find-skills/SKILL.md
@@ -1,4 +1,4 @@
 ---
 name: find-skills
-description: Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.
+description: Find and install agent skills from the public skills ecosystem. Use when the user asks to find, compare, or install a skill, or asks whether one exists for a task. Not for ordinary how-to questions the agent can answer or do directly.
 ---
```

## Verification

These are static checks that were run during the audit. No behavioral probe was run.

- **`coding-standards.md` path** (#1): `git ls-files` lists the file only as `archive/rules/coding-standards.md`. `ls home/skills` and `ls ~/.claude/skills` show no `dlz-environment` (#2). `grep -rn "dlz-environment\|coding-standards" home/` returns only the two cited lines.
- **pii-sweep script** (#4): `pii-sweep.ps1` defines `-Path` and `-DiffRange` and exits 2, 1, 0 or 3. That matches the skill's run instructions, so those were left alone.
- **Conflict lines** (#7, #8): `git log --stat` shows that every conflicting line was introduced in `ec20ee5`. `archive/rules/coding-standards.md:16,18` matches the builder and verifier wording.
- **Out-of-band references**: a grep for the removed strings, excluding `.git`, `claude-setup/` and `skill-evals/`, finds them only in the edited files, `archive/CLAUDE.chief-operator.md` (not loaded) and `docs/phase0-inventory.md` (a historical record). No test or hook matches on them.
