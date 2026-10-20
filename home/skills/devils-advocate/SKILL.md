---
name: devils-advocate
description: Adversarially stress-test a plan, a completion claim, a diff, or an architecture decision before it is accepted. Dispatches the read-only adversarial-critic (fable) to attack the work for fake progress, unproven claims, missing evidence, edge cases, and bloat, then triage its findings. Use before declaring a milestone done, merging a sensitive change, or committing to a design — especially for irreversible or security-relevant work.
---

# Devil's advocate

Before you accept your own work, have it attacked by someone whose only job is to
find what's wrong. This is a review gate, not a rewrite — the critic reads and
reports; you decide what to act on.

## When to use

- Before declaring any milestone "done".
- Before a change that is hard to reverse (production AD/Exchange/Graph writes,
  data migrations, deletes) or security-relevant.
- When a plan feels too clean, or a subagent reported success without evidence.
- Periodically, to audit the system itself for drift and dead weight.

## How to run it

1. **Assemble the target.** Give the critic something concrete: the diff (or file
   list + key files), the claim being made, the acceptance criterion, and any
   evidence already gathered (test output, build log). Vague input yields vague
   findings.
2. **Dispatch `adversarial-critic`** (subagent_type: adversarial-critic, model
   claude-fable-5, read-only). Prompt it to attack, not to agree. Ask specifically
   for: where's the evidence, which file enforces this tomorrow, what edge case
   breaks it, what's unreviewed, what's bloat. Demand concrete pointers
   (file:line, log line), severity-ordered, no preamble.
3. **For high-stakes work, run more than one lens.** Spawn parallel critics with
   distinct angles — correctness, security, does-it-actually-reproduce,
   operational/rollback — instead of one generic pass. Send them in one message so
   they run concurrently.
4. **Triage the findings.** For each: is it real (reproduce or point at the code),
   and does it matter? Confirmed + material → a fix microtask (hand to a builder,
   don't silently patch). Real but immaterial → note and move on. Not real → say
   why it was dismissed.
5. **Report honestly.** Surface what survived triage to the user, including
   anything you're choosing not to fix and why. Do not launder a critique into
   "looks good."

## Rules

- The critic never fixes — it reads and reports. Fixes flow back through builders.
- Don't argue the findings into submission; either refute with evidence or accept.
- A finding that recurs twice is a systemic gap — fix the spec/agent/rule, and
  consider an eval, not just the instance.
- Its output is internal — relay the substance to the user, not the transcript.
