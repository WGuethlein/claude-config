<#
.SYNOPSIS
    risk-guard.ps1 - PreToolUse hook: gates destructive commands before execution.

.DESCRIPTION
    Name:          risk-guard.ps1
    Version:       1.0.0
    Author:        Wyatt Guethlein
    Date:          2026-07-07
    Description:   Reads the PreToolUse hook JSON from stdin, inspects shell
                   commands Claude is about to run, and returns a JSON
                   permissionDecision. Hard-destructive AD/Exchange/Graph/
                   filesystem operations are denied outright; medium-risk
                   writes force an interactive "ask" prompt. Every decision
                   is appended to the audit log.
    Prerequisites: Windows PowerShell 5.1 or later. No modules required.
    Usage:         Wired via ~/.claude/settings.json (PreToolUse, matcher
                   "Bash|PowerShell"). Manual test:
                   '{"tool_name":"Bash","tool_input":{"command":"Remove-ADUser x"}}' |
                     powershell -NoProfile -File "$env:USERPROFILE\.claude\hooks\risk-guard.ps1"

.NOTES
    Exit code is always 0. Decisions are communicated via JSON on stdout:
    no output = no opinion, normal permission flow applies.
#>

# --- Configurable variables -------------------------------------------------

# Audit log location. Directory is created if missing.
$logDir  = Join-Path $env:USERPROFILE ".claude\logs"
$logFile = Join-Path $logDir ("risk-guard-{0}.log" -f (Get-Date -Format "yyyyMM"))

# Patterns that are DENIED outright. Case-insensitive regex, matched against
# the full command string. These are operations with no safe interactive
# recovery: identity deletion, mailbox deletion, Graph deletes, disk-level
# destruction, recursive deletes against UNC paths.
$denyPatterns = @(
    'Remove-AD(User|Group|Computer|Object|ServiceAccount|OrganizationalUnit)\b',
    'Remove-(Mailbox|MgUser|MgGroup|DistributionGroup|UnifiedGroup)\b',
    'Invoke-MgGraphRequest[^|;]*-Method\s+DELETE',
    'Format-Volume|Clear-Disk|Remove-Partition',
    'Remove-Item[^|;]*-Recurse[^|;]*\\\\[a-zA-Z0-9]',   # recursive delete on a UNC path
    'rm\s+-rf\s+/(\s|$)'                                  # rm -rf against root
)

# Patterns that force an interactive ASK. Writes to identity, mailboxes,
# group membership, Graph mutations, service/host restarts, and writes
# against the Panzura share.
$askPatterns = @(
    'Set-(ADUser|ADGroup|ADComputer|ADAccountPassword|Mailbox|MailboxAutoReplyConfiguration|CASMailbox|MgUser)\b',
    '(Add|Remove)-(ADGroupMember|MailboxPermission|RecipientPermission)\b',
    'New-(ADUser|ADGroup|ADServiceAccount|Mailbox|MgUser)\b',
    '(Enable|Disable)-ADAccount\b',
    'Move-ADObject\b',
    'Invoke-MgGraphRequest[^|;]*-Method\s+(PATCH|POST|PUT)',
    'Invoke-(RestMethod|WebRequest)[^|;]*-Method\s+Delete',
    '(Restart|Stop)-(Computer|Service)\b',
    '(Remove|Move|Copy)-Item[^|;]*azure-pan2',
    'rm\s+-rf\s'
)

# --- Functions ---------------------------------------------------------------

function Write-GuardLog {
    param([string]$Message)
    try {
        if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        $line = "{0} {1}" -f (Get-Date -Format "o"), $Message
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        # Logging must never break the hook.
    }
}

function Emit-Decision {
    param(
        [ValidateSet("deny","ask")] [string]$Decision,
        [string]$Reason
    )
    $payload = @{
        hookSpecificOutput = @{
            hookEventName            = "PreToolUse"
            permissionDecision       = $Decision
            permissionDecisionReason = $Reason
        }
    }
    # -Compress keeps it on one line; -Depth covers the nesting.
    $payload | ConvertTo-Json -Depth 5 -Compress
}

# --- Main --------------------------------------------------------------------

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $evt = $raw | ConvertFrom-Json

    # Only shell-command tools carry a .command we can inspect.
    $command = $null
    if ($evt.tool_input -and $evt.tool_input.PSObject.Properties['command']) {
        $command = [string]$evt.tool_input.command
    }
    if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

    foreach ($pattern in $denyPatterns) {
        if ($command -imatch $pattern) {
            $reason = "Blocked by risk guard (pattern: $pattern). This class of operation must be run by the user directly, not by Claude. Do not rephrase the command to evade this guard."
            Write-GuardLog ("DENY  tool={0} pattern={1} cmd={2}" -f $evt.tool_name, $pattern, $command)
            Emit-Decision -Decision "deny" -Reason $reason
            exit 0
        }
    }

    foreach ($pattern in $askPatterns) {
        if ($command -imatch $pattern) {
            $reason = "Medium-risk operation (pattern: $pattern). Requires explicit user approval."
            Write-GuardLog ("ASK   tool={0} pattern={1} cmd={2}" -f $evt.tool_name, $pattern, $command)
            Emit-Decision -Decision "ask" -Reason $reason
            exit 0
        }
    }

    # No opinion: stay silent, normal permission flow applies.
    exit 0
}
catch {
    # A guard that crashes should not block work; log and pass through.
    Write-GuardLog ("ERROR {0}" -f $_.Exception.Message)
    exit 0
}
