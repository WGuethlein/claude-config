---
name: subagent-driven-development
description: Playbook for building a feature through subagents instead of grinding it out in the main context. Use when a task is large enough to split into bounded build units (a new endpoint, workflow, service, migration) and you want the chief operator to stay an orchestrator — decompose, delegate to builder, verify with qa-engineer, critique with adversarial-critic, loop. Pairs with the researcher and devils-advocate skills.
---

# Subagent-driven development

Keep the main session as chief operator. It decides, delegates, digests evidence,
and writes handoffs. It does not write large implementations in its own context.

## When to use

A task that would otherwise mean hundreds of lines across many files, or where a
mistake is expensive (production AD/Exchange/Graph writes, migrations, security).
For a one-line fix, just do it inline — this ceremony is waste at small scale.

## The loop

1. **Confirm intent.** State the goal and the acceptance criterion in one sentence
   each. If either is fuzzy, ask one round of questions, then commit.
2. **Research first (as needed).** Invoke the `researcher` skill to verify every
   cmdlet, API shape, package version, or vendor behavior the build depends on.
   Never let a builder guess an external contract.
3. **Decompose.** Split into microtasks with a clear deliverable and file list
   each. Order them by dependency. A microtask that can't be described in a short
   spec is still too big — split again.
4. **Write the spec per microtask.** For each: exact files to touch, the contract
   (signatures, request/response shapes), the pattern to mirror (point at the
   existing file), constraints (nullability, async, idempotency), and what "done"
   looks like. The builder should not have to infer intent.
5. **Delegate to `builder`** (model: sonnet). One builder per independent unit;
   send independent units in a single message so they run concurrently. Isolate
   with a worktree only when builders would edit the same files in parallel.
6. **Verify with `qa-engineer`** (model: sonnet). PASS/FAIL against the stated
   criterion with evidence inline (build output, test run, diff). "Should work" is
   not a verdict. A FAIL goes back to a builder as a fix microtask — do not patch
   silently in the main context.
7. **Critique with the `devils-advocate` skill** before declaring a milestone done
   — especially for anything irreversible or security-relevant.
8. **Digest and decide.** Read each subagent's report (their raw output is not
   shown to the user — relay what matters). If a failure is systemic, fix the
   system (agent/spec/rule), not just the instance.
9. **Handoff.** Before context grows large, write what changed, what's verified,
   and what's open.

## Rules

- One subagent, one bounded job. Don't hand a builder "implement the feature."
- Evidence or it didn't happen: command output, a passing test, or a diff.
- Model routing (per the global chief-operator rules): builder/qa → sonnet,
  research/log-digests → haiku, adversarial review/architecture → fable,
  orchestration/decisions → opus. Never send a bounded worker task to Opus/Fable;
  never send an architecture decision to Haiku.
- Reuse a running subagent via SendMessage (keeps its context) instead of respawning
  when you're continuing the same thread of work.
- Respect the environment guardrails: never rephrase a guard-denied command to
  evade it — surface it and stop.
