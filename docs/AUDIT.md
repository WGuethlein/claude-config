# Claude Code configuration audit, 2026-10-20

An audit of Wyatt's Claude Code setup after the Phase 1 standardization. It is ranked by impact on a
machine that holds production rights to AD, Exchange, and Entra. Each finding states what is wrong,
why it matters, the recommendation, and the effort. Evidence comes from this machine (command output,
config files, 107 main sessions of transcripts) and from current documentation. Sources are cited inline
and listed at the end. Supporting detail: `docs/phase0-inventory.md`, `docs/phase2-memory-review.md`,
`docs/prompt-audit-2026-10-20.md`, `docs/phase3/workflow-analysis.md`.

## Findings by impact

| # | Finding | Impact | Effort |
|---|---|---|---|
| 1 | Permission mode is wide open on a production-rights machine | Critical | 1 h |
| 2 | The risk guard only sees the typed command, not what a script does | Critical | 3 h |
| 3 | Verification is mostly instruction, rarely run | High | 2 h |
| 4 | The terminal `claude` is stale and its updater has failed since Aug 20 | High | 0.5 h |
| 5 | Plain-text credentials and 160+ accreted allow rules in project settings | High | 1 h |
| 6 | Plugins inject competing instructions and noise | Medium | 1 h |
| 7 | "Never" rules in CLAUDE.md that should be enforced deterministically | Medium | 1 h |
| 8 | Workflow: no plan mode, no /clear, very long mixed sessions | Medium | habit |
| 9 | Code diverges from the conventions | Medium | ongoing |
| 10 | Code intelligence and MCP gaps | Low | 1 h |
| 11 | Skill triggering not tuned; AGENTS.md deferred | Low | 2 h |

---

### 1. Permission mode is wide open on a production-rights machine (Critical, 1 h)

**What's wrong**
- Across 107 main sessions, permission modes were auto 81, bypassPermissions 22, acceptEdits 7, and plan 1 (`docs/phase3/workflow-analysis.md`).
- `~/.claude/settings.json` has no `permissions` block: no default mode, no deny rules, and bypass mode is not disabled.
- Since Aug 14, auto mode has been the default for new sessions on Team plans [whats-new].
- The OS sandbox, which would contain shell commands, does not run on native Windows: "On native Windows, Claude Code runs commands unsandboxed" [sandboxing].

**Why it matters**
- In bypassPermissions mode, nothing prompts. The only control left is the risk-guard hook (a hook "deny" still blocks in bypass mode [hooks]), and finding 2 shows its gaps.
- In auto mode, a classifier decides what to run in place of you. Its built-in blocks target generic danger (`curl | bash`, force-push, IAM grants), not `Disable-ADAccount` [permission-modes].
- On this machine, one bad command acts on the production directory with your credentials.

**Recommendation**
- Put a `permissions` block in `settings/settings.shared.json` (proposal A below):
  - `defaultMode: "default"`
  - `disableBypassPermissionsMode: "disable"`
  - deny rules for AD, Exchange, and Graph writes
  - narrow allow rules for read-only `Get-*` and common dev commands, so you aren't clicking through every read
- If you want to keep auto mode for coding repos, add an `autoMode` block whose `hard_deny` names the AD, Exchange, and Entra write actions [permission-modes].
- Do production-write work in a separate session in default mode.

### 2. The risk guard only sees the typed command, not what a script does (Critical, 3 h)

**What's wrong**
- `hooks/risk-guard.ps1` regex-matches the command string Claude types. It denies AD/mailbox/Graph deletes and asks on AD/mailbox writes (`Set-AD*`, `Disable-ADAccount`, `Move-ADObject`, group-member changes).
- During the Phase 2 evals, subagents ran `Invoke-Pester` on generated scripts containing `Disable-ADAccount`, `Set-ADComputer`, `Move-ADObject`, and Graph member removals. The guard saw only `Invoke-Pester ...`.
- A static check confirmed every write cmdlet was mocked, so nothing ran for real. Safety rested on mock correctness, not on a control.
- Matching is also both too broad and too narrow:
  - **Too broad:** all three October denials were false positives (a filename, a `Get-Command` lookup, a log append).
  - **Too narrow:** it misses `Invoke-Expression`/`iex`, `-EncodedCommand`, `& (Get-Command ...)`, `Invoke-Command -ScriptBlock`, and any `.ps1` file run by path. Permission rules share this limit; the docs say a rule "isn't a security boundary around the program" [permissions].

**Why it matters**
- This is the only deterministic barrier between Claude and production AD.
- False positives train you to ignore it. False negatives are the incident.

**Recommendation** (proposal B)
1. Add `ask` patterns for running code the guard can't see: `Invoke-Pester`, `& .\*.ps1`, `powershell(.exe)? -File`, `pwsh -File`, `Invoke-Expression|iex`, `-EncodedCommand|-enc`, and `Invoke-Command`.
2. Content check: when the command runs a `.ps1`, read that file (and the script a `.Tests.ps1` loads). If it contains an AD, Exchange, Graph, or Intune write cmdlet, ask.
3. Anchor the patterns to cmdlet position (start of a pipeline segment, or after `;`, `|`, `&`), so names inside filenames, strings, and `Get-Command -Name` lists stop matching.
4. Add Pester tests for the guard itself, with a table of commands it must deny, ask on, and allow. That is the right place for tests: the guard is shared code that everything depends on.
5. Layer the permission deny rules from finding 1 on top. Neither layer is complete alone.

### 3. Verification is mostly instruction, rarely run (High, 2 h)

**What's wrong**
- The evidence rule is in CLAUDE.md, but only 45 of 107 sessions (42%) ran any build, test, or linter. PowerShell and Python projects were lowest: Samsara 0/4, PSADT 0/2, powershell-profile 3/11.
- Corrections appeared in 13.8% of user messages, highest in the projects that never verified.
- PSScriptAnalyzer is installed only for Windows PowerShell 5.1. `Get-Module -ListAvailable PSScriptAnalyzer` in pwsh 7.6.7 returns nothing, so three eval runs reported it "not installed" and skipped it.

**Why it matters**
- CLAUDE.md is advisory; hooks are deterministic [best-practices].
- A rule followed 42% of the time is a suggestion.

**Recommendation** (proposal C)
- Add a PostToolUse hook on `Edit|Write` that lints the edited file:
  - `.ps1`/`.psm1`: `powershell.exe -NoProfile -Command Invoke-ScriptAnalyzer -Severity Warning,Error`
  - `.py`: `ruff check`
  - `.cs`: no per-edit build, which is too slow; see below
- It returns findings with `decision: "block"` so Claude fixes them in the same turn [hooks].
- This replaces "remember to run the analyzer" with a check that always runs.
- Install PSScriptAnalyzer for pwsh 7 too (`Install-PSResource PSScriptAnalyzer`, run by you).
- For .NET and Python repos with real test suites (Dayforce, InternalApi), add a per-project Stop hook that runs `dotnet test` or `pytest` and blocks the turn on failure. Guard it with `stop_hook_active` against loops [hooks].
- Keep it per project, not global; most PowerShell scripts have no tests by your choice.

### 4. The terminal `claude` is stale and its updater has failed since Aug 20 (High, 0.5 h)

**What's wrong**
- `C:\Users\wguethlein\.local\bin\claude.exe` is 2.1.235. `~/.claude/.last-update-result.json` records `"outcome":"failed","status":"install_failed"` on 2026-08-20. The latest release is 2.1.304 [changelog].
- The desktop app runs its own newer build, which is why `/doctor prompt-audit` worked there.

**Why it matters** Terminal sessions miss these fixes:
- AGENTS.md read natively (2.1.277)
- `/doctor prompt-audit` (2.1.283)
- the extension of PowerShell allow rules and read-only detection to 32KB commands (2.1.296)
- PreToolUse hooks that block instead of failing open when Git for Windows is missing (2.1.299), which matters directly for the risk guard [changelog]

**Recommendation** Run `claude update`, or reinstall with the native installer, and check `claude --version`. If the update fails again, capture the error; a policy may be blocking writes to `.local\bin`.

### 5. Plain-text credentials and 160+ accreted allow rules in project settings (High, 1 h)

**What's wrong**
- Allow rules in `.claude/settings.local.json`: ProjectSetupFormBot 91, InternalApi 52, SigninService 18, and five others with 1 to 3.
- They come from "always allow" clicks, captured as exact command lines.
- 13 of them contain auth, token, password, or secret terms (InternalApi 3, ProjectSetupFormBot 6, SigninService 4), and one is a wildcarded interpreter.
- None are tracked by git. InternalApi and SigninService ignore the file, and ProjectSetupFormBot is not a repo.

**Why it matters**
- Credentials sit in plain text in a file Claude reads at every session start.
- One-off allows add up to an approval list nobody has reviewed.

**Recommendation**
- Open those three files, remove every rule that carries a credential, and rotate any token that turns out to be real.
- Replace one-off rules with the short, reviewed allowlist in proposal A, kept at user level.
- After cleanup, add `Read(**/.env)` and `Read(**/*.pfx)` deny rules.

### 6. Plugins inject competing instructions and noise (Medium, 1 h)

**What's wrong**
- **superpowers 6.2.0:**
  - It injects `using-superpowers` into every session as `<EXTREMELY_IMPORTANT>`, with a "1% chance means you MUST invoke a skill" rule.
  - `brainstorming` has a HARD-GATE on every task.
  - Its TDD and verification skills use "Iron Law" and "delete it" language that cuts against your stop-before-deleting rule (`docs/prompt-audit-2026-10-20.md`).
  - It is also the main driver of autonomous skill use (brainstorming 13, writing-plans 7, subagent-driven-development 9).
- **autoharness 0.3.3:**
  - Its MCP server failed to connect this session.
  - Its hooks call `PYTHONPATH=... python3`, Unix syntax.
  - Its agents are pinned to Haiku and biased toward creating skills.
  - It drops `.claude/autoharness/` folders into whatever directory an agent works in, including eval workspaces.
- **The claude.ai plugin set adds about 70 skills unrelated to IT work:** marketing, product-management, the zoom plugin (30+), and enterprise-search. They load into every session's skill list (about 10k tokens), compete for triggering, and several have failing connectors (zoom: AUTH_HEADER_REJECTED).

**Why it matters**
- Every injected instruction competes with your CLAUDE.md, and the loudest wins.
- Irrelevant skills make the right skill less likely to trigger.

**Recommendation**
- Disable autoharness.
- Turn off the marketing, product-management, and zoom plugins for your account in claude.ai, unless you use them.
- Keep superpowers for now, but watch it. If brainstorming keeps gating simple tasks, disable it in the repos where `spec` should drive planning. Editing the plugin is pointless; updates overwrite it.
- Your own skills will still trigger on their descriptions (finding 11).

### 7. "Never" rules in CLAUDE.md that should be enforced deterministically (Medium, 1 h)

**What's wrong** These CLAUDE.md lines are rules with no mechanism:
- AD is read-only for Claude
- never run SQL against production
- no secrets in code
- no real tenant, server, or OU names in git

**Recommendation**
- **AD read-only:** deny rules for `*-AD*` writes (proposal A) plus the guard (proposal B).
- **Production SQL:** a guard `ask` on `Invoke-Sqlcmd`, `sqlcmd`, and `Invoke-DbaQuery` when the server matches a production list kept in local config, not in git.
- **Secrets:** a PreToolUse hook on `Edit|Write` that blocks writes to `.env`, `*.pfx`, `*.key`, and `*credential*` paths, and blocks content matching token patterns (proposal D) [hooks-guide].
- **Real identifiers:** a pre-push `pii-sweep` (already a skill) plus a tenant-ID and OU-path grep. Keep the CLAUDE.md lines as the reason; the hooks are the enforcement.

### 8. Workflow: no plan mode, no /clear, very long mixed sessions (Medium, habit)

**What's wrong**
- Plan mode in 1% of sessions.
- `/clear` in 0 sessions, and compaction in only 2, while 26 sessions ran past 1,000 events and 28% crossed working directories.
- Specs written before code in 33% of code-editing sessions, mostly in Dayforce and Metafield.
- Worktrees in 5 sessions.
- Subagents are heavy (529 calls in 41 sessions), with general-purpose used almost as often as builder.

**The one habit change with the biggest payoff:** one task per session, and the task isn't done until a check has run.
- Start a fresh session, or `/clear`, when the task changes.
- Let the lint and test hooks (finding 3) make the check automatic, so the habit costs nothing to keep.
- Long, mixed sessions are where context degrades, and unverified endings are where corrections come from.
- Plan mode or `spec` for anything you expect to run long is the second-order version of the same habit.

### 9. Code diverges from the conventions (Medium, ongoing)

See "Your code against the conventions" below.

### 10. Code intelligence and MCP gaps (Low, 1 h)

**Code intelligence** [code-intelligence]
- `csharp-lsp` (needs `csharp-ls`) and `pyright-lsp` (needs `pyright-langserver`) are official plugins. They give Claude go-to-definition and diagnostics, which helps most in InternalApi-sized .NET solutions. Install both.
- There is no official PowerShell LSP plugin. One could be built on PowerShellEditorServices; that's untested and not worth it yet.

**MCP**
- Atlassian and Microsoft 365 already reach Claude Code as claude.ai connectors (they show in this session).
- GitHub is covered by `gh`, which CLAUDE.md already prefers; the GitHub MCP server adds little for a solo user.
- Remove or fix the zoom connectors, which fail auth every session.

### 11. Skill triggering not tuned; AGENTS.md deferred (Low, 2 h)

- Claude Code already picks skills on its own from their descriptions: 74 autonomous Skill calls in history. That is the autonomy Wyatt wants.
- `find-skills` was never invoked; it installs third-party skills, globally and without confirmation.
- The lever for autonomy is description quality. Run skill-creator's description optimizer on `spec`, `ps-script`, and `it-writeup` when there's budget for it: about 20 test queries per skill, three runs each, up to five rounds.
- `find-skills` should keep requiring your confirmation before installing anything, given the CMMC exposure.
- AGENTS.md is deferred; start with Dayforce when you pick it up. Claude Code reads AGENTS.md natively since 2.1.277, but only when no CLAUDE.md exists in that tree. Otherwise keep `@AGENTS.md` in CLAUDE.md [memory].

---

## Your code against the conventions

Samples, picked by latest commit:
- PowerShell: `powershell-profile` (WyattTools, 52 files)
- Python: `Samsara/src/function.py`
- .NET: `BenefitsReports`, plus `InternalApi` for the comment issue

This was a read-only review; nothing was run. I spot-checked the headline counts myself: strict mode and `#Requires` 0 of 52, "harness" comments 22, EF Core references in InternalApi Core, return type hints 0 of 29.

**What you're doing wrong, ranked by production and audit risk**

1. **The PowerShell module has no `Set-StrictMode`, no `$ErrorActionPreference = 'Stop'`, and no `#Requires` in any of its 52 files.**
   - Only `WyattTools.psd1` states 5.1.
   - Risk: a mistyped variable becomes `$null`, and a failed AD call carries on to the next user. That is in a module that edits groups.
   - Fix: set all three once in `WyattTools.psm1`, which dot-sourced `Public/*.ps1` files inherit, and add "Target: 5.1" to the header template. See the rule change below.
2. **Transcripts on only 3 of 51 files.**
   - `Copy-ADGroupMembership` has the right pattern (line 54).
   - Other mutating commands, such as `Remove-ADGroupUser`, need checking.
   - Fix: every command that calls a mutating cmdlet gets `Start-Transcript` in `try`/`finally`.
3. **Samsara (`function.py`, 1,405 lines) has no checks of any kind.**
   - No type hints (0 of 29 functions return-annotated), no module docstring, and a nested function (line 832).
   - A roughly 450-line `handler()`.
   - No `pyproject.toml`, ruff, or tests.
   - It emails driver reports, and a change to it can't be verified.
   - Fix: add `pyproject.toml` with ruff and pytest, split `handler()`, and write one test for the reporting window and one for a failure path.
4. **InternalApi's Core project references EF Core, EF InMemory, SqlServer, and HealthChecks.**
   - Only the Web project sets `TreatWarningsAsErrors`.
   - This is an identity-provisioning API that writes AD and Exchange.
   - Fix: copy BenefitsReports' `Directory.Build.props`, and move the data references into Infrastructure.
5. **InternalApi comments carry project history.**
   - 22 "harness" references ("Ported from the SC-RenameAccount console harness", `Core/Identity/IdentityOperations.cs:27`), "exactly as before Phase 2" (`Infrastructure/Common/Jobs/TransientFailure.cs:12`), "(reliability spine Phase 2)", and about 58 lines of "ported from", "legacy", or "as before".
   - powershell-profile and BenefitsReports are clean on this, with history in commit messages.
   - Fix: one clean-up pass on InternalApi. The new CLAUDE.md rule stops new ones.

**Lower risk**
- One type per file: `PostmanCollection.cs` has 16 types, `ApiModels.cs` 14.
- 25 `catch (Exception` in BenefitsReports.
- No `IValidateOptions` in BenefitsReports.
- 15 `-ErrorAction SilentlyContinue` and 84 `Write-Host` in WyattTools.
- One real email domain committed in InternalApi's Web `appsettings.json` (move it to the overlay).

**Where your code is better than the rules (rule changes to consider)**
- **Native dry runs:** `Copy-FolderFast` maps `-WhatIf` to robocopy `/L`, which shows real counts and does nothing. Add to `powershell.md`: where the tool has a native dry run, map `-WhatIf` to it.
- **Scheduled apps:** BenefitsReports gives each failure class its own exit code and uses an overlap lock for scheduled runs. Add a "scheduled and CLI apps" line to `dotnet.md`.
- **Preview tests:** BenefitsReports pins its preview mode with tests asserting it sends, moves, and deletes nothing. That is the one kind of test worth requiring: any dry-run or preview mode gets a side-effect test. It fits your "tests only when they earn it" preference.
- **Module scope:** `powershell.md` asks every script for StrictMode and `#Requires`. For module function files, which are dot-sourced, the module root should carry them instead. Say so, or every module function is out of compliance by design.
- **BenefitsReports is the model .NET repo:** `net10.0`, `Nullable`, `TreatWarningsAsErrors`, and `EnforceCodeStyleInBuild` in `Directory.Build.props`, 74 test files, 0 `async void`.

---

## Trends from the last six months that the drafts don't reflect

1. **Auto mode became the Team default (Aug 14).**
   - Hard deny rules (W19) and destructive-git blocking (W25) arrived alongside it.
   - Bearing on you: the drafts assume prompts; the default no longer prompts. Finding 1 [whats-new].
2. **Windows-native PowerShell matured.**
   - Git Bash is no longer required (W18).
   - PowerShell permission rules now parse the command AST: aliases are canonicalized, and rules apply per pipeline segment [permissions].
   - Hooks fail closed instead of open (2.1.299).
   - Bearing on you: PowerShell allow and deny rules are now practical, so finding 1 can be done with rules, not only regex.
3. **Instruction checks.**
   - `/doctor prompt-audit` (2.1.283) and the `/doctor` setup checkup (W28).
   - Bearing on you: run it quarterly, as the README says [whats-new].
4. **Skill and plugin evals.**
   - `claude plugin eval` (W37) scores a plugin against a no-plugin baseline.
   - `/skill-doctor` (W36) shows each skill's context cost and usage.
   - Bearing on you: it formalizes the with/without-skill loop run in Phase 2, and `/skill-doctor` would quantify finding 6 [whats-new].
5. **AGENTS.md went native and neutral.**
   - Read natively since 2.1.277.
   - Now stewarded by the Linux Foundation's Agentic AI Foundation [memory; openai.com/blog/agentic-ai-foundation].
6. **Models.**
   - Opus 5.5 (Sep 22, 1M context, about 40% cheaper than Opus 5), Sonnet 5.5 (late Sep), Haiku 5.5 (Oct 7; its tokenizer produces about 30% more tokens), Fable 5.1 in Claude Code (W36).
   - Bearing on you: agent model pins should use aliases (`sonnet`, `opus`), as they now do. Haiku's tokenizer change matters for any cost estimate [anthropic.com].
7. **Background and parallel work became default.**
   - Background subagents (W27), fork mode (W33), the `claude agents` view (W20), and dynamic workflows (W22).
   - Agent teams are still experimental and lack split panes in Windows Terminal.
   - Bearing on you: the hand-built orchestration retired in Phase 1 is now built in [whats-new; agent-teams].
8. **Spec-driven development.**
   - GitHub Spec Kit (Spec, Plan, Tasks, Implement) supports Claude Code; practitioners report documentation overhead.
   - Bearing on you: your `spec` skill is the lighter version of this, and the Phase 2 evals showed it works (100% vs 29%) [spec-kit].

---

## Org admin: what should be managed vs personal (flag only, nothing deployed)

**Mechanisms**
- **Server-managed settings:** the admin console, under Organization settings > Claude Code. Clients fetch them at startup and hourly. They can't target groups yet. They are a "client-side control, not a security boundary" [server-managed-settings].
- **Endpoint-managed settings:**
  - `C:\Program Files\ClaudeCode\managed-settings.json` (plus a `managed-settings.d\` folder and `managed-mcp.json`)
  - or `HKLM\SOFTWARE\Policies\ClaudeCode\Settings` (REG_SZ JSON) via Intune or GPO; HKLM takes priority over the file
  - templates in `anthropics/claude-code` `examples/mdm` [managed-settings]
- **Managed CLAUDE.md:** at `C:\Program Files\ClaudeCode\CLAUDE.md`. Users can't exclude it [memory].

**Candidates for org-wide management**
- `permissions.disableBypassPermissionsMode: "disable"`: no DLZ user needs to skip all prompts.
- `autoMode` `hard_deny` entries for AD, Exchange, and Entra writes, if auto mode stays allowed.
- `strictKnownMarketplaces` / `blockedMarketplaces`, plus `allowManagedMcpServersOnly` with an allowlist: limits third-party code and connectors under CMMC.
- A short managed CLAUDE.md covering:
  - CUI handling (never paste CUI into a session)
  - no secrets in chat
  - stop before production writes

  These hold for every DLZ user regardless of role.

**Keep personal**
- CLAUDE.md, rules, skills, agents, output styles, keybindings, statusline, auto memory, model preferences, and personal allow rules.
- Your risk guard stays personal unless you set `allowManagedHooksOnly`. If you do, move it into the managed tier first, or it stops running.
- Endpoint policy won't restrict you as a local admin. It does stop Claude from loosening its own limits, because writing to Program Files or HKLM needs elevation.

---

## Proposed settings (not installed; approve each)

**A. Permissions** (`settings/settings.shared.json`, merged by `install.ps1`):
```json
"permissions": {
  "defaultMode": "default",
  "disableBypassPermissionsMode": "disable",
  "deny": [
    "PowerShell(Set-AD*)", "PowerShell(New-AD*)", "PowerShell(Remove-AD*)",
    "PowerShell(Disable-ADAccount*)", "PowerShell(Enable-ADAccount*)", "PowerShell(Move-ADObject*)",
    "PowerShell(Add-ADGroupMember*)", "PowerShell(Remove-ADGroupMember*)",
    "PowerShell(Set-Mailbox*)", "PowerShell(Remove-Mailbox*)",
    "PowerShell(Update-Mg*)", "PowerShell(Remove-Mg*)", "PowerShell(New-Mg*)",
    "Read(**/.env)", "Read(**/*.pfx)"
  ],
  "allow": [
    "PowerShell(Get-*)", "PowerShell(Test-Path *)", "PowerShell(Select-String *)",
    "PowerShell(Invoke-ScriptAnalyzer *)",
    "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)",
    "Bash(dotnet build*)", "Bash(dotnet test*)", "Bash(ruff *)", "Bash(pytest*)"
  ]
}
```
- `PowerShell(Get-*)` is broad on purpose: `Get-` cmdlets read.
- Deny rules apply to typed commands only (finding 2), so the guard stays as the second layer.

**B. Risk guard v2:** edits to `home/hooks/risk-guard.ps1`, per the five items in finding 2, with a Pester table test. No settings change.

**C. Lint after edit** (`settings.shared.json` hooks plus a new `home/hooks/lint-on-edit.ps1`):
```json
"PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "shell": "powershell",
  "command": "& \"$env:USERPROFILE\\.claude\\hooks\\lint-on-edit.ps1\"", "timeout": 60 }]}]
```
- The script reads `tool_input.file_path` from stdin, runs PSScriptAnalyzer through `powershell.exe` for `.ps1`/`.psm1` or `ruff check` for `.py`, and returns `{"decision":"block","reason":...}` on findings.

**D. Secret-path block** (PreToolUse on `Edit|Write`, a new `home/hooks/protect-secrets.ps1`):
- Exits 2 for `.env`, `*.pfx`, `*.key`, `secrets\`, and `*credential*` paths.
- Exits 2 for content matching `sk-ant-`, `ghp_`, `AKIA`, or a private-key header.

**E. Test gate:** a per-project Stop hook for Dayforce and InternalApi only, running their test command and honoring `stop_hook_active`.

## Sources

- [hooks] https://code.claude.com/docs/en/hooks
- [hooks-guide] https://code.claude.com/docs/en/hooks-guide
- [permissions] https://code.claude.com/docs/en/permissions
- [permission-modes] https://code.claude.com/docs/en/permission-modes
- [sandboxing] https://code.claude.com/docs/en/sandboxing
- [managed-settings] https://code.claude.com/docs/en/managed-settings
- [server-managed-settings] https://code.claude.com/docs/en/server-managed-settings
- [memory] https://code.claude.com/docs/en/memory
- [best-practices] https://code.claude.com/docs/en/best-practices
- [code-intelligence] https://code.claude.com/docs/en/plugins/code-intelligence
- [mcp] https://code.claude.com/docs/en/mcp
- [agent-teams] https://code.claude.com/docs/en/agent-teams
- [whats-new] https://code.claude.com/docs/en/whats-new
- [changelog] https://code.claude.com/docs/en/changelog
- [mdm] https://github.com/anthropics/claude-code/tree/main/examples/mdm
- [anthropic.com] https://www.anthropic.com/claude-opus-5-5, https://www.anthropic.com/claude-haiku-5-5
- [spec-kit] https://github.github.com/spec-kit/
- https://openai.com/blog/agentic-ai-foundation

Not verified:
- whether a hook's `shell: powershell` launches powershell.exe (5.1) or pwsh (7.x); test with `$PSVersionTable` in a hook before relying on 5.1-only modules
- the PowerShell-specific ways around deny rules; inferred from the documented Bash cases
- which plans include the M365 connector; sources conflict
