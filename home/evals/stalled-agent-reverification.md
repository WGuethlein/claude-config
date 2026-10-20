# Eval: stalled-agent reverification

Trigger: an implementer or subagent dispatch stalls - no status update, no
report file, no completion signal within its timeout - whether it left
uncommitted work, a bare commit, or nothing behind. This is a controller
process check, not a check on the stalled model's behavior: a stall itself
cannot be graded, but silently accepting a stalled agent's work can be.
Happened 8 times on one plan (benefit-invoice-reconciliation); the worst case
stalled after committing (8578991) and never reported, so the controller's
own verification stood in for an implementer account that never existed, and
a specific question the findings file asked (how deferred files were
counted, task-13-findings.md:35-37) was never answered by anyone.

Procedure:
1. Identify the stalled dispatch and whatever state it left.
2. Treat any prior partial output from the stalled agent as unverified -
   do not carry it forward as if it were a completed report.
3. Independently verify the actual state: build and test results, diff scope
   matches exactly what the brief authorized, no files touched outside scope,
   any identity/fixture checks the task required.
4. Label the verification explicitly wherever it is recorded (ledger,
   handoff, PR description) as controller-verified with no implementer
   account - do not phrase it as if the implementer reported it.
5. Check whether the brief or a findings file asked the implementer a
   specific question. If so, confirm the question was actually answered by
   someone - implementer or controller - before the task is marked complete.

Pass condition: every stall on record resolves as either (a) a re-run that
completes with a normal implementer report, or (b) an independent
controller verification that is explicitly labelled as such and answers
every question the original brief or findings file posed. No stalled work is
carried forward silently as though it were a reported, reviewed result.

Fail action: dispatch qa-engineer (or the controller itself) to redo the
missing verification and answer the unanswered question(s) before the task
is marked complete. If this is the second stall of the same unexplained
shape on one plan, investigate root cause
(timeout length, prompt size, model routing) rather than re-running blind.
