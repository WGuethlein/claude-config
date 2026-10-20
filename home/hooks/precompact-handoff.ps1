<#
.SYNOPSIS
    precompact-handoff.ps1 - PreCompact hook: preserves a pointer to the full transcript before compaction.

.DESCRIPTION
    Name:          precompact-handoff.ps1
    Version:       1.0.0
    Author:        Wyatt Guethlein
    Date:          2026-07-07
    Description:   Fires before Claude Code compacts context. Appends the
                   session id, compaction trigger (manual/auto), and the
                   transcript path to ~/.claude/handoffs/handoffs.log so the
                   pre-compaction state is always recoverable, and surfaces a
                   visible reminder that a handoff checkpoint was recorded.
    Prerequisites: Windows PowerShell 5.1 or later. No modules required.
    Usage:         Wired via ~/.claude/settings.json (PreCompact, matcher "*").

.NOTES
    Exit code is always 0.
#>

# --- Configurable variables -------------------------------------------------

$handoffDir  = Join-Path $env:USERPROFILE ".claude\handoffs"
$handoffFile = Join-Path $handoffDir "handoffs.log"

# --- Main --------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $evt = $raw | ConvertFrom-Json

    if (-not (Test-Path $handoffDir)) { New-Item -Path $handoffDir -ItemType Directory -Force | Out-Null }

    $line = "{0} session={1} trigger={2} transcript={3}" -f `
        (Get-Date -Format "o"), [string]$evt.session_id, [string]$evt.trigger, [string]$evt.transcript_path
    Add-Content -Path $handoffFile -Value $line -Encoding UTF8

    # systemMessage surfaces to the user without affecting the compaction.
    $out = @{ systemMessage = "Pre-compaction checkpoint recorded in ~/.claude/handoffs/handoffs.log" }
    $out | ConvertTo-Json -Compress

    exit 0
}
catch {
    exit 0
}
