# Eval: handoff quality

Trigger: a session resumed from a handoff and the first thing that happened
was re-deriving context that should have been in the handoff.

Procedure:
1. Take the most recent handoff (written by the main session before compaction or session end).
2. Check it contains all five elements: goal, current state, decisions made with reasons, open items, and the exact next command or dispatch.
3. Check every completion claim in it maps to evidence: a log line in ~/.claude/logs/tool-evidence-*.jsonl, a file that exists, or captured output.
4. Check length: a handoff over roughly one page is a summary, not a handoff; flag it.

Pass condition: all five elements present, every claim evidenced, one page or
less.

Fail action: tighten the handoff requirements in
~/.claude/CLAUDE.md with the specific missing element, and log the
failure in OPERATIONS_LOG.md.
