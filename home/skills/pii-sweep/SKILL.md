---
name: pii-sweep
description: Scan a repository (or a diff range) for real data that leaked into source, tests, or docs, before a push. Goes beyond digit-shape matching by flagging prose that claims a nearby value is real, and files that redact an identifier in one place while printing one in another. Use before any push on a repo that touches carrier census data, employee identifiers, or any other real-person data.
---

# PII sweep

A digit-shape grep alone is not a PII sweep. It classifies hits by whether
they "look invented" and never reads the sentence next to them, which is how
real identifiers get cleared as fixtures. This skill checks the prose too.

## When to use

- Before every push on any branch that touches carrier census, payroll, or
  employee-identifier data (or any other real-person data).
- Whenever a spec, plan, or brief documents a value read from a real source
  file - "the workbook", "the live report", "the actual export" - even if
  the value looks like an obvious test fixture.
- As part of a whole-branch or handoff review, not only at push time.

## How to run it

1. Run the script from a shell that has PowerShell 5.1+ available:
   ```
   powershell -NoProfile -File ~/.claude/skills/pii-sweep/pii-sweep.ps1 -Path <repo-root>
   ```
   To scope to a diff instead of the whole tree:
   ```
   powershell -NoProfile -File ~/.claude/skills/pii-sweep/pii-sweep.ps1 -Path <repo-root> -DiffRange "main...HEAD"
   ```
2. Read the output in this order:
   - **HIGH escalations** (exit code 2): a file has both a digit-shaped
     literal and language claiming a value nearby is real ("verified by
     reading", "the real workbook", ...), or a file both claims to redact
     identifiers and prints a digit-shaped one. Treat every HIGH escalation
     as real until someone traces the specific value to its actual source and
     proves otherwise. Do not clear one because it "looks like" a fixture.
   - **Digit-shaped literals with no escalation** (exit code 1): still needs
     manual triage. Trace each to the scrub or fixture set that supposedly
     produced it - do not accept "it's nine digits and doesn't look real" as
     the basis for clearing it.
3. If anything is real: scrub forward (replace the value everywhere it was
   copied - tests, specs, plans, generated docs). Do not rewrite git history
   without the operator's explicit direction; note in the handoff whether a
   rewrite was considered and why it was or wasn't done.
4. Record the result. If a value cleared as HIGH turns out to have been real,
   this is a repeat of the same failure class - see
   `~/.claude/evals/pii-realness-sweep.md` and log it in OPERATIONS_LOG.md.

## Rules

- Never classify a digit-shaped value as safe purely because it "traces to
  an invented fixture set" without independently confirming that against the
  real source data (e.g. grepping the actual reference file, if one exists
  and is safe to grep).
- A realness claim near a value ("verified by reading the real workbook") is
  evidence the value is real, not evidence it's fine because someone
  documented it. Read the prose, not just the digits.
- A document that redacts a category of data in one place must not print an
  instance of it elsewhere. That contradiction is itself a finding, in
  addition to whatever the printed value turns out to be.
- This sweep does not replace judgment - it removes the specific failure mode
  where judgment substituted for reading. HIGH escalations still need a human
  or reviewing agent to look, they just can no longer be silently cleared.
