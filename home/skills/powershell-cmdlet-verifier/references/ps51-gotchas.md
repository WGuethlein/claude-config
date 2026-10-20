# PowerShell 5.1 Gotchas — the incompatibility screen

Scan every script for these before presenting. Each has caused a real runtime failure in
this environment. Windows PowerShell 5.1 is the default target; all items below are
things that exist in PowerShell 7.x but **fail on 5.1**.

## Syntax that does not parse on 5.1

These are hard parse errors on 5.1 — the script will not even load.

| 7.x construct | Example | 5.1 replacement |
|---|---|---|
| Ternary operator | `$x ? $a : $b` | `if ($x) { $a } else { $b }` |
| Null-coalescing | `$a ?? $b` | `if ($null -ne $a) { $a } else { $b }` |
| Null-coalescing assign | `$a ??= $b` | `if ($null -eq $a) { $a = $b }` |
| Null-conditional | `${a}?.Prop` / `${a}?[0]` | explicit `$null` check before access |
| Pipeline chain operators | `cmd1 && cmd2` / `cmd1 \|\| cmd2` | check `$?` or `$LASTEXITCODE`, or try/catch |
| `clean {}` block | `clean { }` in a function | not available; use `finally` / `end` |

## Cmdlet parameters that are 6.0+ only (do not exist in 5.1)

Using any of these throws "A parameter cannot be found that matches parameter name ...".

| Cmdlet | 7.x-only parameter | 5.1 approach |
|---|---|---|
| `Invoke-RestMethod` / `Invoke-WebRequest` | `-ResponseHeadersVariable` | use `Invoke-WebRequest` and read `.Headers` off the response object |
| `Invoke-RestMethod` / `Invoke-WebRequest` | `-StatusCodeVariable` | use `Invoke-WebRequest`, read `[int]$resp.StatusCode`; on error read status from the `WebException` (see below) |
| `Invoke-RestMethod` / `Invoke-WebRequest` | `-SkipHttpErrorCheck` | non-2xx **throws** on 5.1 — wrap in try/catch and recover from `$_.Exception.Response` (see below) |
| `Invoke-RestMethod` / `Invoke-WebRequest` | `-Form` | build `multipart/form-data` manually or via `System.Net.Http` |
| `Invoke-RestMethod` | `-AllowInsecureRedirect`, `-Retry*`, `-ConnectionTimeoutSeconds`, `-OperationTimeoutSeconds` | use `-TimeoutSec`; implement retry manually |
| `ConvertTo-Json` / `ConvertFrom-Json` | `-AsHashtable` (ConvertFrom), `-EnumsAsStrings` | post-process manually |
| `ConvertFrom-Json` | `-Depth` (5.1 `ConvertTo-Json` HAS `-Depth`, default 2 — set it explicitly; but `ConvertFrom-Json` gained `-Depth` in 7.x) | be explicit about `ConvertTo-Json -Depth`; do not rely on `ConvertFrom-Json -Depth` on 5.1 |
| `Test-Connection` | `-TargetName`, `-Ping`, `-Traceroute` (reshaped in 6+) | use 5.1 shape: `-ComputerName`, `-Count`, `-Quiet` |
| `Start-Process` | `-WhatIf` behavior differs | verify |
| `Get-Random` | `-Shuffle` | 7.x only |

## HTTP on 5.1 — the canonical pattern

`Invoke-WebRequest`/`Invoke-RestMethod` **throw a terminating error on any non-2xx**
status in 5.1 (there is no `-SkipHttpErrorCheck`). To inspect an error body/status you
must catch and dig it out of the response stream:

```powershell
$requestArgs = @{
    Method          = $Method
    Uri             = $Uri
    ErrorAction     = 'Stop'
    UseBasicParsing = $true    # avoid IE-engine dependency on some 5.1 hosts
}
try {
    $response   = Invoke-WebRequest @requestArgs
    $statusCode = [int]$response.StatusCode
    $rawBody    = $response.Content
}
catch [System.Net.WebException] {
    $webResponse = $_.Exception.Response
    if ($null -ne $webResponse) {
        $statusCode = [int]$webResponse.StatusCode
        $reader = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
        try   { $rawBody = $reader.ReadToEnd() }
        finally { $reader.Dispose() }
    }
    else {
        # DNS failure, connection refused, timeout — no HTTP response at all
        $statusCode = $null
        $rawBody    = $_.Exception.Message
    }
}
```

`-UseBasicParsing` should be set on `Invoke-WebRequest` in 5.1; without it the cmdlet can
depend on the Internet Explorer DOM engine, which may be absent on Server Core / hardened
hosts. (It became the default/no-op in 6+, so it is harmless on 7.x.)

## TLS

5.1 does not negotiate TLS 1.2 by default against some endpoints. Force it before web
calls when talking to older/stricter servers:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

## Other 5.1 behaviors to watch

- **`#Requires -Version 5.1`** belongs at the top of every script targeting 5.1, plus
  `#Requires -Modules <name>` for hard module dependencies. This turns a vague runtime
  failure into a clear refusal to run.
- **No `-Parallel` on `ForEach-Object`** (7.x only). Use workflows, runspaces, or jobs if
  parallelism is genuinely needed — but usually a plain loop is fine.
- **`ForEach-Object` has no `-ThrottleLimit`** (pairs with `-Parallel`).
- **Classes and enums** exist in 5.1 but with rough edges (module reload quirks, limited
  inheritance). Prefer functions + `PSCustomObject` unless a class is clearly warranted.
- **`using namespace` / `using module`** exist in 5.1 but must be the very first
  non-comment lines; misplacement is a parse error.
- **`$PSStyle`** (output formatting) is 7.2+ only.
- **`Clean` blocks, experimental features, `&` background operator returning a job** —
  treat anything you remember as "recent" as suspect and verify.

## How to use this list

Treat it as a checklist, not an exhaustive spec. If a construct is not on the list but
you have any doubt whether it existed in 5.1, that doubt is the signal to verify via
`Get-Command`/`Get-Help` on a 5.1 host or Microsoft Learn (with version filter), per the
main SKILL workflow.
