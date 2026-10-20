---
name: researcher
description: Verify external facts before building — cmdlet names and parameters, API request/response shapes, SDK method signatures, package versions, vendor behavior and error messages. Dispatches bounded lookups to research-scout (haiku) or, for broad code sweeps, Explore, so a builder never guesses an external contract. Use whenever a fact needs checking rather than assuming, especially before generating PowerShell, Graph/REST calls, or anything touching a third-party service.
---

# Researcher

Guessing an external contract is how a builder ships a call that fails at runtime.
Check the fact first, cheaply, and hand the verified answer to the builder.

## When to use

- Before generating any PowerShell: confirm the cmdlet exists, its exact
  parameters, and module/version (target PowerShell 5.1 on servers unless told
  otherwise — no ternary, no null-coalescing, no PS7-only params).
- Before an API/SDK call: confirm the endpoint, method, request/response shape,
  and the SDK method signature for the version actually referenced in the repo.
- Before pinning a dependency: confirm the current stable version and known CVEs.
- When an error message is unfamiliar: find its documented cause before reacting.
- To locate where something lives across many files: a broad code sweep.

## How to run it

1. **State the question as a verifiable claim**, not "look into X". E.g. "Confirm
   `Set-RemoteMailbox -RemoteRoutingAddress` is the correct way to change an
   existing remote mailbox's routing address in Exchange 2016 management shell,"
   not "research remote mailboxes."
2. **Pick the worker:**
   - **research-scout** (subagent_type: research-scout, model haiku) — bounded
     external/factual lookups: cmdlets, APIs, versions, docs, error messages.
     Tools: Read, Grep, Glob, WebSearch, WebFetch.
   - **Explore** — broad read-only sweeps across the codebase when you need to
     find where/how something is done, not verify an external fact.
   - Batch independent questions into parallel dispatches in one message.
3. **Demand grounded answers.** Require a source (doc URL, or the repo file:line
   that already uses the pattern) and the exact signature/shape — not a paraphrase.
   Prefer verifying against the version the repo pins, checked in code, over
   generic web memory.
4. **Fold the verified fact into the build spec.** The builder receives the
   confirmed contract, not a pointer to "go research it."

## Rules

- Never let the main session burn context on a lookup a scout can do — but never
  send an architecture decision to a scout either.
- Prefer primary sources (vendor docs, the SDK's own types) over blogs.
- If a fact can't be verified, say so and flag the risk; don't let a builder
  proceed on an unverified external contract.
- Cross-check any web claim against what the repo actually references before acting.
