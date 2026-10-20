---
name: spec
description: Interview Wyatt and write a SPEC.md before building anything non-trivial. Use this whenever he asks for a new script, tool, feature, automation, report pipeline, or process change that has more than a couple of inputs, touches production systems (AD, Exchange, Entra, Intune, M365), or would take more than one session. Also use it when he says "spec", "plan this out", "let's design", or describes something vague enough that you'd otherwise guess. Not for one-line fixes or questions.
---
# Spec

The point of this skill is to find the hard parts before any code or document exists, then leave a self-contained SPEC.md that a fresh session can execute without the conversation that produced it.

## Procedure
1. Restate the goal in two sentences and name what kind of thing this is (script, service, report, process change, document). Confirm before interviewing.
2. Interview with the AskUserQuestion tool, a few questions at a time. Skip anything already answered in the conversation or derivable from the repo. Cover, in roughly this order:
   - Inputs and outputs: exact sources, formats, destinations, volumes.
   - Target environment: PowerShell 5.1 vs 7.6, which servers or tenants, permissions and consent needed, scheduled vs on-demand.
   - Failure handling: what happens on partial failure, retries, idempotency, who gets notified.
   - Safety: dry-run expectations, blast radius, rollback, anything touching CUI or audit scope.
   - Non-goals: what is explicitly out of scope for this pass.
   - Verification: how we will know it worked (a test, a sample run against a pilot OU, a diff against a known-good export).
3. Keep going until there are no open questions you'd otherwise resolve by guessing. Don't ask the obvious.
4. Write `SPEC.md` in the project root using the structure below. Then tell Wyatt to start a fresh session with "implement SPEC.md" so implementation gets clean context.

## SPEC.md structure
```
# <Name>
## Goal
## Context (environment, constraints, target versions)
## Inputs / Outputs
## Behavior (numbered, including error paths)
## Non-goals
## Files and interfaces to create or change
## Verification (the exact check that proves it works)
## Open questions (should be empty when done)
```

Keep it specific enough to verify and short enough to read in five minutes. Name files and interfaces; don't write the implementation.
