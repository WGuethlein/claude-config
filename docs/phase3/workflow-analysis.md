# Workflow analysis from session history, 2026-10-20

Read-only analysis of 107 main sessions (641 subagent transcripts excluded) across 23 project folders,
July to October 2026. Counts only; no message content was read for quoting. The correction regex is
noisy (it matches "don't" and "stop" used as ordinary instructions), so treat that rate as an upper bound.

| Practice | Measure | Verdict |
|---|---|---|
| Plan mode | 2 of 107 sessions (1%). Permission modes seen: auto 81, bypassPermissions 22, acceptEdits 7, plan 1 | Almost unused; 26 sessions ran past 1,000 events |
| Specs/plans | 25 sessions wrote a spec or plan; 16 of 49 code-editing sessions (33%) wrote it before the first edit | Partial, concentrated in Dayforce and Metafield |
| Subagents | 41 sessions, 529 calls (builder 219, general-purpose 198, critic 50, qa 25); 11 sessions over 20 calls | Heavy, and general-purpose is used almost as often as builder |
| Worktrees | 5 of 107 | Barely used, including in the parallel-build sessions where they fit |
| /clear | 0 sessions; compaction in 2 | Never used; 28% of sessions crossed working directories |
| Verification | 45 of 107 (42%) ran a build, test, or linter; PowerShell/Python projects lowest (Samsara 0/4, PSADT 0/2, powershell-profile 3/11) | The evidence rule is not being met |
| Corrections | 133 of 963 user messages (13.8%); highest in small projects without verification | Suggestive link to missing verification |

Biggest habit change (agent's conclusion): make verification a default gate before "done", then start
anything expected to run long with plan mode or a short spec, and start a fresh session per task.
