<#
.SYNOPSIS
    session-logger.ps1 - SessionStart hook: writes one audit line per session.

.DESCRIPTION
    Name:          session-logger.ps1
    Version:       1.0.0
    Author:        Wyatt Guethlein
    Date:          2026-07-07
    Description:   Fires when a session starts or resumes. Appends session id,
                   start source (startup/resume/clear/compact), and working
                   directory to the sessions log. Gives the operational log
                   and evidence trail a session-level anchor to correlate
                   against.
    Prerequisites: Windows PowerShell 5.1 or later. No modules required.
    Usage:         Wired via ~/.claude/settings.json (SessionStart, matcher "*").

.NOTES
    Exit code is always 0.
#>

# --- Configurable variables -------------------------------------------------

$logDir  = Join-Path $env:USERPROFILE ".claude\logs"
$logFile = Join-Path $logDir "sessions.log"

# --- Main --------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $evt = $raw | ConvertFrom-Json

    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

    $source = ""
    if ($evt.PSObject.Properties['source']) { $source = [string]$evt.source }

    $line = "{0} session={1} source={2} cwd={3}" -f `
        (Get-Date -Format "o"), [string]$evt.session_id, $source, [string]$evt.cwd
    Add-Content -Path $logFile -Value $line -Encoding UTF8

    exit 0
}
catch {
    exit 0
}
