# Evals

An eval is a repeatable check born from a repeated failure. Each eval is one
markdown file the qa-engineer agent can execute verbatim. When a failure shows
up twice in OPERATIONS_LOG.md, it gets an eval; the eval is the system's
immune memory.

Format per eval file:

- Trigger: the failure pattern this guards against
- Procedure: exact steps or commands the qa-engineer runs
- Pass condition: objective, checkable
- Fail action: what gets dispatched when it fails (usually a config fix in the main session or builder with a specific instruction)

Run cadence: dispatch qa-engineer with "run all evals in ~/.claude/evals/"
after significant system changes, or individually when the related work type
occurs.
