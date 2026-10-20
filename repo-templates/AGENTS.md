# <Project name>

<!-- Read by Claude Code, GitHub Copilot, Cursor, and Codex. Keep under 150 lines.
     Project facts only; personal preferences live in ~/.claude/. -->

## What this is
Two to four sentences: purpose, who uses it, where it runs.

## Stack and targets
- Language and version (e.g. PowerShell 7.6 / Windows PowerShell 5.1 / Both; Python 3.14; .NET 10 / C# 14)
- Key dependencies and the systems it talks to (AD, Exchange, Graph, MetaField, Samsara, SQL)

## Commands
- Build:
- Test:
- Lint:
- Run locally:
- Dry run against production data:

## Layout
Only the parts that aren't obvious from the tree. Where entry points, config, and tests live.

## Conventions that differ from defaults
- 
- 

## Guardrails
- Never run against production tenants without `-WhatIf` / `--dry-run` first.
- Secrets come from <env var / SecretManagement vault / Key Vault name>; never commit them.
- Files or folders that must not be edited by an agent:

## Gotchas
- Non-obvious behaviors, flaky tests, environment quirks.
