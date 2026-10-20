# Eval: PowerShell 5.1 cmdlet verification

Trigger: generated PowerShell that uses guessed cmdlet names, guessed
parameters, or PS7-only syntax on scripts destined for servers.

Procedure:
1. Take the most recently produced PowerShell script in the current task.
2. Static syntax check without executing:
   powershell -NoProfile -Command "[void][System.Management.Automation.Language.Parser]::ParseFile('<script path>', [ref]$null, [ref]$errs); $errs | ForEach-Object { $_.Message }"
3. Scan the script for PS7-only constructs: ternary (?:), null-coalescing (??), pipeline chain operators (&& / || between cmdlets), ForEach-Object -Parallel.
4. For each cmdlet used from a non-core module (ActiveDirectory, ExchangeOnlineManagement, Microsoft.Graph.*), confirm every parameter name exists via Get-Command <cmdlet> -Syntax on a machine with the module, or via the Microsoft Learn docs if the module is unavailable locally.

Pass condition: zero parse errors, zero PS7-only constructs, every checked
parameter confirmed to exist.

Fail action: return the exact offending line(s) to builder with instruction
"verify against Get-Command -Syntax / Microsoft Learn and correct; do not
substitute another guess."
