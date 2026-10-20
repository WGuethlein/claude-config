# Phase 2 memory review, 2026-10-20

A read-only comparison of auto memory (57 topic memories plus 11 MEMORY.md indexes, across 12
project folders) against the new `home/CLAUDE.md` and rules. It found no true duplicates and no
hard contradictions, so nothing was deleted. The items below are candidates to promote into the
global file. They are pending Wyatt's decision.

## Candidates to promote into home/CLAUDE.md

| Source memories | Rule | Target |
|---|---|---|
| Metafield/never-query-bst-prod, Dayforce/operator-runs-all-sql | Claude never executes SQL against production databases; it hands over the query for the operator to run | Stop-and-confirm bullet |
| InternalApi/ad-read-only-never-write | AD is read-only for Claude (stricter than confirm-before-write) | Stop-and-confirm bullet |
| InternalApi/config-no-real-secrets-in-git, powershell-profile/profile-repo-workflow | No real tenant IDs, server names, or OU paths in git-tracked files | No-secrets bullet |
| Metafield/discuss-before-code-changes, SDDesign/recommend-then-let-user-choose | When a request has competing readings, lay them out with a recommendation and let me choose before acting | Plan-before-changing bullet |
| SDDesign/always-use-subagent-driven-execution | Execute written plans with subagents, not inline | Context section (only if global) |

## Soft conflict to resolve

InternalApi/adversarial-review-model-routing records that Fable failed with a usage-credits error,
and that the critic should run on `opus` instead. Phase 1 set `adversarial-critic` to `model: fable`.
If Fable is still unavailable on this account, the critic agent fails. Decide between pinning it
to `opus` and keeping `fable`.

## Housekeeping

InternalApi/config-no-real-secrets-in-git contradicts itself (`REPLACE_ME` versus blank strings).
