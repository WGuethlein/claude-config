# Eval: plan-versus-artifact drift

Created 2026-09-14, after the failure appeared twice in one task of the evaluation-viewer build.

## The failure it catches

A review finding is recorded as fixed because the PLAN was edited, while the built artifact never
changed. The plan looks complete, the ledger says the finding is closed, and the code does not carry it.

It is insidious because every signal a controller normally trusts says the work is done: the plan
contains the fix, the implementer reported DONE, and the tests pass - they pass because the missing
change was a test or a comment that nothing else depends on.

## How it happened

The controller patched the plan, then dispatched a fix round telling the implementer to "re-read the
brief file", without regenerating that brief from the patched plan. The brief on disk still held the
pre-fix text.

Findings the dispatch spelled out literally were all implemented. Both findings it delegated to the
stale file were missed. The implementer noticed the file was out of step, said so, and built from the
dispatch instead - which is the correct behaviour and is the only reason it was caught.

## The check

Given a task whose review produced findings, and a fix round that claims to have addressed them:

1. For each finding, grep for its artefact in `src/` and `tests/`, NOT in the plan.
2. A finding whose only occurrence is in a `docs/` path is NOT addressed, regardless of what the
   ledger says.
3. Where a fix round regenerates a brief, confirm the brief's modification time is later than the
   plan commit it derives from.

## The system patch

Regenerate the task brief in the SAME command that commits a plan patch. Never point an implementer at
a brief file without regenerating it first. Verify a finding as closed against the built artifact.

## Note on the second-order lesson

The controller also "synced" the plan to match built code after reading only part of that code, which
left the plan a non-faithful record of the file on disk. Anyone regenerating from it would produce a
different test suite. Sync in that direction requires reading the whole file, not a grep of it.

## Instance 3 (2026-09-14, eval-viewer-site, commit 628b662)

The hardest version of this failure: it occurred inside a commit whose entire purpose was correcting
an earlier mistake. The commit message describes rewriting a code comment and relabelling three tests.
`git show --stat` shows one file changed: the plan document.

Why the earlier rule did not catch it: the rule said "a finding is closed only when its artifact
appears under src/ or tests/". The Tasks 6+7 fix round DID produce artifacts under src/ and tests/
(commits 2526d63, 26497ac), so the rule read as satisfied. The correction commit that followed was
treated as documentation because its subject line began with "docs:".

Tightened rule: evaluate closure PER FINDING, not per round, and for prose remedies the evidence is a
grep of the shipped file. "docs:" as a commit prefix does not exempt a change from this - if the thing
being corrected lives in code, the commit is not a docs commit.

Detection that worked: the scoped re-reviewer ran `git show --stat` on the correction commit rather
than trusting its message, and read both comment blocks on disk.
