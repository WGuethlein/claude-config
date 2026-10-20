# Coding Standards (condensed)

Condensed working conventions imported by the global CLAUDE.md. This is the
enforcement copy; the full preference document lives in claude.ai user
preferences and should be treated as authoritative if the two diverge.

## All languages

- KISS, DRY, YAGNI, single responsibility. Simple string methods over regex unless the pattern is genuinely complex (then comment the regex).
- No emojis in documentation. Files open with a 2-4 sentence description.
- Ask clarifying questions before writing code.

## PowerShell

- Verify cmdlet names, parameters, and required modules before generating. Never guess.
- Script structure, in order: header block (name, version, author, date, description, prerequisites, usage example), configurable variables at top with comments, CLI parameters with validation that override defaults, then code with what/why comments.
- Try/catch with logging, Write-Verbose for operational detail, -WhatIf on destructive operations, test required modules/permissions at start, approved verbs, PascalCase functions, $camelCase variables, splat complex cmdlets, transcript logging for audit-relevant scripts.
- Target PowerShell 5.1 compatibility for anything that runs on servers unless told otherwise: no ternary operator, no null-coalescing, no PS7-only parameters.

## C# / .NET

- Latest stable .NET, nullable reference types enabled, explicit nullability everywhere, no null! suppression without justification.
- XML doc comments on public surface. PascalCase types/members, camelCase locals, _camelCase private fields, I-prefix interfaces, Async suffix on async methods, file name matches type name.
- Async for all I/O. No async void outside event handlers. ConfigureAwait(false) in libraries.
- Constructor injection only. Transient = stateless, Scoped = per-request/EF contexts, Singleton = config and caching.
- Three-layer structure: Core (entities, no dependencies) <- Infrastructure (data, services) <- Web (UI). Each significant type in its own file, namespaces match folders.
- EF Core: async only, configurations via IEntityTypeConfiguration<T>, avoid N+1 with projection or explicit loading.
- Options pattern for config, User Secrets in dev, records for DTOs.

## Output contract for builder work

Code with file paths, affected projects, NuGet packages with versions, config
entries, Program.cs registrations, manual steps, security notes, and testing
recommendations.
