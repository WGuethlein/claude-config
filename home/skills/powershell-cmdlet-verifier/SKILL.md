---
name: powershell-cmdlet-verifier
description: Verify that every cmdlet, parameter, and module in PowerShell code actually exists on the target version BEFORE presenting the script. Use this whenever writing, editing, or reviewing any PowerShell for the DLZ environment — especially anything with Invoke-RestMethod/Invoke-WebRequest, Graph, ActiveDirectory, Exchange, or Az cmdlets, or any script that will run on Windows PowerShell 5.1. Guessing cmdlet or parameter names is the single most common failure in this environment; this skill exists to catch version-mismatched cmdlets, parameters that do not exist in 5.1, and 5.1-incompatible syntax before they reach the user and waste a debugging cycle. Trigger it for new scripts, edits to existing scripts, and "why does this PowerShell error" questions.
---

# PowerShell Cmdlet Verifier

The single most recurring failure when producing PowerShell for this environment is
**emitting a cmdlet, parameter, or syntax construct that does not exist on the target
version** — most often using a PowerShell 7.x feature in a script that will run on
Windows PowerShell 5.1. Each occurrence looks correct, ships, and fails at runtime on the
user's machine, burning a full round-trip. This skill is a verification gate: confirm
before presenting, never guess.

The default target is **Windows PowerShell 5.1** (the DLZ server-side runtime) unless the
user states otherwise. "Windows PowerShell" = 5.1; "PowerShell" / `pwsh` = 7.x.

## The rule

Before presenting any PowerShell, every cmdlet, every parameter, and every module
reference must be confirmed to exist on the target version. If a fact cannot be
confirmed, either verify it with a tool or state the uncertainty explicitly — do not
present an unverified name as if it were correct.

## Verification workflow

Work through these in order. Stop as soon as a step gives you a confident answer.

### 1. Screen against the known 5.1 incompatibility list

Read `references/ps51-gotchas.md` and scan the code for every item on it. This is the
fastest, highest-yield check because these constructs account for most real failures.
Do this even for code that looks obviously fine.

### 2. Statically parse the script (syntax gate)

Parsing catches syntax that the version can't compile (e.g. ternary and null-coalescing
operators do not exist in 5.1 and are parse errors there). If a runtime for the target
version is available, parse with the target runtime; otherwise reason from the gotchas
list.

Windows PowerShell 5.1:
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$errors)
$errors   # any entries = syntax that will not run on 5.1
```
Or for a file: `[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)`.

Note: a parse pass on a 7.x host will happily accept 7.x-only syntax, so parsing alone
does not prove 5.1 compatibility — it must be combined with step 1 and the target runtime.

### 3. Confirm cmdlet and parameter existence

For each cmdlet whose signature you are not certain of on the target version:
```powershell
Get-Command <CmdletName> -ErrorAction SilentlyContinue    # exists at all?
(Get-Command <CmdletName>).Parameters.Keys                # which parameters exist?
Get-Help <CmdletName> -Parameter <ParamName>              # this parameter, this version?
```
If a target-version PowerShell host is reachable (e.g. via a tool or the user can run a
probe), prefer running these there. If not, use authoritative documentation (step 4) and
mark the claim as documentation-derived rather than machine-confirmed.

### 4. Fall back to authoritative docs, with version awareness

When no target runtime is reachable, verify against Microsoft Learn, checking the
version applicability and the "introduced in" note for each parameter. The Microsoft
Learn MCP connector is available in this environment and is the preferred source; web
search of `learn.microsoft.com` is the fallback. Many parameters were added in PS 6.0+
and silently do not exist in 5.1 — the docs state this per-parameter.

### 5. When still uncertain, say so

If a name cannot be confirmed by any of the above, present the code with the specific
line flagged: state that the cmdlet/parameter could not be verified for the target
version and give the user a one-line probe they can run. An admitted gap is recoverable;
a confidently wrong name fails silently.

## Module-specific cautions

Some modules are version- or edition-sensitive in ways that cause the same class of
failure. See `references/module-notes.md` for the specifics that have bitten this
environment: the `ActiveDirectory` (RSAT) module, Microsoft Graph SDK v5 namespace/type
churn, Exchange Online (EXO) cmdlets with no .NET equivalent, and `Az`. Read it whenever
the script touches any of those.

## Output

When the code is clean, present it and briefly note what was verified and how (e.g.
"cmdlets/parameters confirmed against 5.1 via Get-Command; no 7.x-only syntax"). When a
fix was made, name the specific incompatibility caught (e.g. "removed
`-ResponseHeadersVariable`, which is 6.0+ only; recovered headers from the
`Invoke-WebRequest` response object instead") so the reasoning is visible and reusable.

Do not present PowerShell with unverified cmdlets or parameters as if it were confirmed.
Silence about verification reads as "verified"; if you did not check, say you did not
check.
