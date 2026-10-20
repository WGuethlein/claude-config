# Eval: PII realness sweep

Trigger: a pre-push or pre-commit sweep for PII/real data is about to run,
has just declared a branch clean, or a spec/plan/brief documents a value
read from a real source file. Happened twice on one repository
(benefit-invoice-reconciliation): Task 1 test fixtures copied out of real
report output, and a spec table headed "Verified ... by reading the real
workbook" whose values were real and got adopted into five test files and
pushed. Both times the sweep in use classified hits by digit shape and
"traces to the invented fixture set" and never read the prose sitting next
to the values.

Procedure:
1. Run:
   `powershell -NoProfile -File ~/.claude/skills/pii-sweep/pii-sweep.ps1 -Path <repo-root> [-DiffRange <range>]`
2. Review every HIGH escalation (exit code 2): a file carrying both a
   digit-shaped literal and realness language ("verified by reading", "the
   real workbook", "from the live", ...), or a file that both claims to
   redact identifiers and prints a digit-shaped one nearby. These are not
   judgment calls - treat the value as real until it is specifically traced
   to its actual source and disproved.
3. Review every remaining digit-shaped finding (exit code 1) by hand. Do not
   accept "it traces to the invented fixture set" as sufficient on its own;
   confirm against the real source data (e.g. grep the actual reference file
   if one exists and is safe to grep).

Pass condition: zero HIGH escalations, and every remaining digit-shaped
finding has been manually traced to its source with the confirmation basis
recorded (for example, "Task 1 scrub verified zero occurrences of the
originals").

Fail action: dispatch builder to scrub the value forward - every file it was
copied into, tests and docs alike - without rewriting git history unless the
operator explicitly directs a rewrite. Record the scrub in OPERATIONS_LOG.md
if this is a repeat occurrence, and re-run the sweep before push.
