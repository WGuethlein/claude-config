---
paths:
  - "**/*.ps1"
  - "**/*.psm1"
  - "**/*.psd1"
---
# PowerShell conventions

## Target declaration (every script)
- The header names the target: `Windows PowerShell 5.1`, `PowerShell 7.6`, or `Both`. Add a matching `#Requires -Version` line. If I didn't say which, ask before writing.
- For 5.1 or Both: no ternary `?:`, no `??` / `??=`, no `&&` / `||` pipeline chains, no `ForEach-Object -Parallel`, no `Get-Error`, no `-SkipCertificateCheck`, no `ConvertFrom-Json -AsHashtable`, no `Join-String`. Use `[System.Management.Automation.PSVersionHashTable]`-safe constructs and `Test-Path`/`Get-Command` guards for anything 7-only.
- For 7.6: use the modern syntax freely; still call out anything that would break on 5.1 if the script could plausibly land on a DC or legacy server.

## Script layout, in this order
1. Comment-based help plus a header block: name, version, author, date, description, target version, prerequisites (modules, permissions, AD required Y/N), usage example.
2. `#Requires` lines, `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`.
3. `[CmdletBinding(SupportsShouldProcess)]` and `param()` with validation attributes and help text. Parameters override the defaults in step 4.
4. Configurable variables with comments and sensible defaults.
5. Functions, then main logic. Comment sections with what and why.

## Behavior
- Prerequisite checks up front: required modules (`Get-Module -ListAvailable`), permissions, connectivity. Fail early with a clear message.
- try/catch with specific exception types where they exist; log with `Write-Verbose` for operational detail, `Write-Warning` for recoverable issues. `Start-Transcript` for anything that changes AD, Exchange, Entra, or endpoints.
- Destructive actions go through `$PSCmdlet.ShouldProcess()` so `-WhatIf` works. Default to reporting, opt in to changing.
- Validate input before acting on it. Splat cmdlets with more than three parameters. Approved verbs, PascalCase functions, camelCase variables.
- Microsoft Graph via `Microsoft.Graph` SDK or direct Graph calls; never `AzureAD` or `MSOnline` (retired). Exchange via `ExchangeOnlineManagement` for cloud, remote PowerShell for HYBRID1.

## Verification
- Run `Invoke-ScriptAnalyzer -Path <file> -Severity Warning` and fix findings before handing the script back. Paste the result.
- For anything beyond a one-off, add a Pester 5 test file next to the script covering parameter validation and the dry-run path.
- Confirm every cmdlet and parameter with `Get-Command` / `Get-Help -Parameter` in the target version. Say explicitly when you could not verify something.

## Delivery
- Script, then: explanation, manual steps (consent, permissions, scheduling), risks, and how to test safely (a pilot OU, `-WhatIf`, a single mailbox).
