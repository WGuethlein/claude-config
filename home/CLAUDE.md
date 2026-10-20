<!-- User-level instructions. Loads in every Claude Code and Cowork session, coding or not.
     Keep under 60 lines. Language conventions live in ~/.claude/rules/ and load only when
     matching files are touched. Procedures live in ~/.claude/skills/. -->

# About me
- IT/DevOps at DLZ Corp, an AEC firm with ~30 offices. Hybrid AD, Exchange 2019 hybrid, Entra, M365; Intune, SCCM, CrowdStrike, Zscaler, Cisco ISE. NIST 800-171 / CMMC exposure.
- Most sessions are code (PowerShell, Python, C#/.NET, SQL). Many are not: admin analysis, reports, documentation, licensing and vendor work. Do not assume a task is code until it is.

# How to work
- Plan before changing anything you can't describe in one sentence: read the relevant files, then give me a short plan and wait. For a new feature, tool, or script with more than a couple of inputs, use the `spec` skill.
- Ask when a requirement, input/output shape, or error-handling choice is genuinely ambiguous. Settle anything you can by reading the code or docs instead of asking.
- Verify, then show evidence. Run the build, tests, linter, or script and paste the result. Do not report work as done without a check that actually ran. If there is no check, say so and propose one. Verdicts are PASS or FAIL with the output inline; "should work" is not a completion state.
- Fix root causes. Never suppress errors, skip tests, or loosen assertions to get a pass.
- Stay in scope. Mention out-of-scope problems you noticed; don't fix them unasked.
- Stop and confirm before anything destructive or production-touching: AD, Exchange, Entra, Intune, Graph writes, deleting files, force-push, schema changes. Scripts default to dry-run / -WhatIf.
- The risk-guard hook denies or asks on destructive AD, Exchange, Graph, disk, and UNC-delete commands. If it blocks a command, surface it to me and stop. Never rephrase a command to get past it.
- No secrets in code, config, or chat. Point to env vars, SecretManagement, or Key Vault and say where the value should come from.
- Flag CUI handling, credential exposure, or audit-trail implications when they appear.

# Defaults
- Python 3.14, .NET 10 LTS / C# 14, PowerShell 7.6 or Windows PowerShell 5.1 (every script declares which). Say when something needs a newer version than the target.
- Native Windows. The Bash tool is Git Bash; the PowerShell tool is pwsh 7. Server-side scripts usually run on Windows PowerShell 5.1.
- Verify cmdlet, API, and package names against docs or --help before using them. Do not guess parameters. For PowerShell, use the `powershell-cmdlet-verifier` skill.
- Prefer CLI tools (gh, az, dotnet, pwsh, m365) over describing clicks.

# Output
- Concise. No emojis in code, docs, commit messages, or chat. Plain prose for explanations; bullets only for real lists.
- Every source file starts with a 2-4 sentence description of what it is and why it exists.
- Comments describe the code for a reader who never saw our conversation. Never reference the chat, the requester, review findings, spec or task numbers, or earlier versions ("per Wyatt", "as discussed", "fixes B7", "spec 3.3", "previously"). That history belongs in the commit message.
- Code deliveries include: file paths, what changed, the verification command and its result, risks, manual steps.
- Non-code deliverables (memos, analyses, recommendations) lead with the recommendation, then findings, then detail. Use the `it-writeup` skill for anything going to leadership.

# Context
- Use subagents for codebase investigation and log reading; keep the main thread for decisions. Delegate bounded, well-specified builds to `builder`, independent verification to `qa-engineer`, and pre-acceptance review of milestones or risky designs to `adversarial-critic`. Small edits stay in the main thread.
- Suggest /clear when we switch to an unrelated task.
- When compacting, preserve: the goal, current state, modified files, verification commands and results, decisions made, open items, and the exact next step.

# Failure log
- When the same mistake happens twice, append one line to `~/.claude/OPERATIONS_LOG.md`: `date | failure | root cause | system patch | eval created | next`. Nothing else goes in it.
- A failure logged twice becomes an eval in `~/.claude/evals/` (format in `evals/README.md`). Prefer a hook over an eval when the check can be made deterministic.
