<#
.SYNOPSIS
    evidence-logger.ps1 - PostToolUse hook: appends a JSONL audit record per tool call.

.DESCRIPTION
    Name:          evidence-logger.ps1
    Version:       1.0.0
    Author:        Wyatt Guethlein
    Date:          2026-07-07
    Description:   Reads the PostToolUse hook JSON from stdin and appends a
                   compact one-line JSON record (timestamp, session, tool,
                   truncated input) to a daily JSONL file. Provides the
                   evidence trail for delivery-gate reviews and a CMMC-friendly
                   record of what the agent actually did.
    Prerequisites: Windows PowerShell 5.1 or later. No modules required.
    Usage:         Wired via ~/.claude/settings.json (PostToolUse, matcher "*",
                   async). Manual test:
                   '{"session_id":"t","tool_name":"Bash","tool_input":{"command":"whoami"}}' |
                     powershell -NoProfile -File "$env:USERPROFILE\.claude\hooks\evidence-logger.ps1"

.NOTES
    Runs async; must never block or throw. Exit code is always 0.
#>

# --- Configurable variables -------------------------------------------------

$logDir       = Join-Path $env:USERPROFILE ".claude\logs"
$maxInputLen  = 400   # truncate serialized tool_input beyond this many characters

# --- Main --------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $evt = $raw | ConvertFrom-Json

    $inputSummary = ""
    if ($evt.PSObject.Properties['tool_input'] -and $evt.tool_input) {
        $inputSummary = ($evt.tool_input | ConvertTo-Json -Depth 3 -Compress)
        if ($inputSummary.Length -gt $maxInputLen) {
            $inputSummary = $inputSummary.Substring(0, $maxInputLen) + "...[truncated]"
        }
    }

    $record = @{
        ts      = (Get-Date -Format "o")
        session = [string]$evt.session_id
        tool    = [string]$evt.tool_name
        input   = $inputSummary
    }

    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    $logFile = Join-Path $logDir ("tool-evidence-{0}.jsonl" -f (Get-Date -Format "yyyyMMdd"))
    Add-Content -Path $logFile -Value ($record | ConvertTo-Json -Depth 3 -Compress) -Encoding UTF8

    exit 0
}
catch {
    exit 0
}
