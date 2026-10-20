<#
.SYNOPSIS
    risk-guard.ps1 - PreToolUse hook: gates destructive commands and hidden code execution.

.DESCRIPTION
    Name:          risk-guard.ps1
    Version:       2.0.0
    Author:        Wyatt Guethlein
    Date:          2026-10-20
    Target:        Windows PowerShell 5.1 (runs under the hook's powershell shell)
    Description:   Reads the PreToolUse hook JSON from stdin, inspects the shell
                   command Claude is about to run, and returns a JSON
                   permissionDecision. Destructive AD/Exchange/Graph/disk
                   operations are denied. Directory and mailbox writes, and any
                   command that runs code the guard cannot see (a .ps1 file,
                   Pester, Invoke-Expression, encoded commands), force an "ask".
                   For script runs, the guard reads the script and names the
                   write cmdlets it contains in the prompt. Cmdlet patterns only
                   match in command position, so cmdlet names inside filenames,
                   strings, or Get-Command lookups do not trigger. Every decision
                   is appended to the audit log.
    Prerequisites: Windows PowerShell 5.1 or later. No modules required. AD required: N.
    Usage:         Wired via ~/.claude/settings.json (PreToolUse, matcher
                   "Bash|PowerShell"). Tests: hooks\tests\risk-guard.Tests.ps1.

.NOTES
    Exit code is always 0. Decisions are communicated via JSON on stdout:
    no output = no opinion, normal permission flow applies.
#>

# --- Configurable variables -------------------------------------------------

# Audit log location. Directory is created if missing.
$logDir  = Join-Path $env:USERPROFILE ".claude\logs"
$logFile = Join-Path $logDir ("risk-guard-{0}.log" -f (Get-Date -Format "yyyyMM"))

# A cmdlet counts as being invoked only at the start of a command segment:
# line start, after ; | & ( { } =, or right after -Command / -c and an optional quote.
$cmdStart = '(?:^|[;|&({}=]|(?:-Command|-c)\s+[''"]?)\s*'

# DENIED outright: identity and mailbox deletion, Graph deletes, disk-level
# destruction, recursive deletes against UNC paths. No safe interactive recovery.
$denyPatterns = @(
    ($cmdStart + 'Remove-AD(User|Group|Computer|Object|ServiceAccount|OrganizationalUnit)\b'),
    ($cmdStart + 'Remove-(Mailbox|MgUser|MgGroup|DistributionGroup|UnifiedGroup)\b'),
    'Invoke-MgGraphRequest[^|;]*-Method\s+[''"]?DELETE',
    ($cmdStart + '(Format-Volume|Clear-Disk|Remove-Partition)\b'),
    'Remove-Item(?=[^|;]*\s-Recurse)[^|;]*\\\\[a-zA-Z0-9]',
    'rm\s+-rf\s+/(\s|$)'
)

# Force an ASK: directory, mailbox, and Graph writes; restarts; writes to the Panzura share.
$askPatterns = @(
    ($cmdStart + 'Set-(ADUser|ADGroup|ADComputer|ADAccountPassword|ADObject|Mailbox|MailboxAutoReplyConfiguration|CASMailbox|MgUser)\b'),
    ($cmdStart + '(Add|Remove)-(ADGroupMember|ADPrincipalGroupMembership|MailboxPermission|RecipientPermission)\b'),
    ($cmdStart + 'New-(ADUser|ADGroup|ADComputer|ADServiceAccount|Mailbox|MgUser)\b'),
    ($cmdStart + '(Enable|Disable|Unlock)-ADAccount\b'),
    ($cmdStart + '(Move|Rename|Restore)-ADObject\b'),
    'Invoke-MgGraphRequest[^|;]*-Method\s+[''"]?(PATCH|POST|PUT)',
    'Invoke-(RestMethod|WebRequest)[^|;]*-Method\s+[''"]?Delete',
    ($cmdStart + '(Restart|Stop)-(Computer|Service)\b'),
    '(Remove|Move|Copy)-Item[^|;]*azure-pan2',
    'rm\s+-rf\s'
)

# Force an ASK: commands that run code whose contents the patterns above never see.
$hiddenCodePatterns = @(
    'Invoke-Pester\b',
    'Invoke-Expression\b|(^|[;|&({}=\s])iex(\s|$)',
    '\s-(EncodedCommand|enc|ec)\s',
    'Invoke-Command\b',
    '&\s*\(\s*Get-Command',
    '(powershell|pwsh)(\.exe)?\s[^|;]*-File\b',
    '(^|[;|&\s])&\s*[''"]?[^\s''"|;]+\.ps1\b',
    '(^|[;|&\s])\.\s+[''"]?[^\s''"|;]+\.ps1\b',
    '(^|[;|&\s])\.\\[^\s''"|;]+\.ps1\b'
)

# Write cmdlets that make a script worth naming in the prompt.
$scriptWritePattern = '\b(Set|New|Remove|Add|Enable|Disable|Unlock|Move|Rename|Restore|Update|Grant|Revoke)-(AD\w+|Mg\w+|Mailbox\w*|CASMailbox|DistributionGroup\w*|UnifiedGroup\w*|InboxRule|IntuneManagedDevice\w*|Team\w*)\b|Invoke-MgGraphRequest[^\r\n]*-Method\s+[''"]?(DELETE|PATCH|POST|PUT)'

# --- Functions ---------------------------------------------------------------

function Write-GuardLog {
    param([string]$Message)
    try {
        if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        $line = "{0} {1}" -f (Get-Date -Format "o"), $Message
        Add-Content -Path $logFile -Value $line -Encoding UTF8
    } catch {
        # Logging must never break the hook.
        Write-Verbose "Risk guard log write failed: $($_.Exception.Message)"
    }
}

function Get-ScriptWriteCmdlet {
    # Returns the distinct write cmdlets found in .ps1 files the command would run.
    # For Invoke-Pester, the scripts next to the test path count too, because tests load them.
    param([string]$Command, [string]$WorkingDirectory)
    $paths = @()
    foreach ($m in [regex]::Matches($Command, '[''"]?((?:[A-Za-z]:)?[^\s''"|;&]*\.ps1)\b')) {
        $paths += $m.Groups[1].Value
    }
    if ($Command -imatch 'Invoke-Pester\b') {
        # Scan the folder Pester will run: the -Path value if it is a folder, else the test file's folder,
        # else the working directory. Depth and count are capped so the hook stays inside its timeout.
        $target = '.'
        if ($Command -imatch 'Invoke-Pester\b[^|;]*?-Path\s+[''"]?([^\s''"|;]+)') { $target = $Matches[1] }
        $targetFull = if ([System.IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $WorkingDirectory $target }
        $dir = if (Test-Path -LiteralPath $targetFull -PathType Leaf) { Split-Path $targetFull -Parent } else { $targetFull }
        if (Test-Path -LiteralPath $dir -PathType Container) {
            $paths += @(Get-ChildItem -LiteralPath $dir -Filter *.ps1 -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 50 -ExpandProperty FullName)
        }
    }
    $found = @()
    foreach ($p in ($paths | Select-Object -Unique)) {
        $full = if ([System.IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $WorkingDirectory $p }
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
            if ($text) { $found += @([regex]::Matches($text, $scriptWritePattern, 'IgnoreCase') | ForEach-Object { ($_.Value -split '\s')[0] }) }
        }
    }
    return @($found | Sort-Object -Unique)
}

function Get-GuardDecision {
    # Returns @{ Decision = 'deny'|'ask'|$null; Reason; Pattern } for one command string.
    param([string]$Command, [string]$WorkingDirectory = (Get-Location).Path)
    foreach ($pattern in $denyPatterns) {
        if ($Command -imatch "(?m)$pattern") {
            return @{ Decision = 'deny'; Pattern = $pattern; Reason = "Blocked by risk guard: this deletes or destroys directory, mailbox, Graph, or disk objects. The user must run it directly. Do not rephrase the command to evade this guard." }
        }
    }
    foreach ($pattern in $askPatterns) {
        if ($Command -imatch "(?m)$pattern") {
            return @{ Decision = 'ask'; Pattern = $pattern; Reason = "Risk guard: this writes to AD, Exchange, Graph, a service, or the Panzura share. Approve only if Claude explained what changes and why." }
        }
    }
    foreach ($pattern in $hiddenCodePatterns) {
        if ($Command -imatch "(?m)$pattern") {
            $writes = Get-ScriptWriteCmdlet -Command $Command -WorkingDirectory $WorkingDirectory
            $detail = if ($writes.Count -gt 0) { " The code it runs calls: $($writes -join ', '). Unmocked, these run for real under your credentials." } else { " No directory, mailbox, or Graph write cmdlets were found in the scripts it names." }
            return @{ Decision = 'ask'; Pattern = $pattern; Reason = "Risk guard: this runs code the guard cannot inspect line by line (a script, Pester, or an expression).$detail" }
        }
    }
    return @{ Decision = $null; Pattern = $null; Reason = $null }
}

function Write-Decision {
    param([ValidateSet("deny","ask")] [string]$Decision, [string]$Reason)
    $payload = @{
        hookSpecificOutput = @{
            hookEventName            = "PreToolUse"
            permissionDecision       = $Decision
            permissionDecisionReason = $Reason
        }
    }
    $payload | ConvertTo-Json -Depth 5 -Compress
}

# --- Main --------------------------------------------------------------------

# Dot-sourcing (the tests do this) loads the functions without reading stdin.
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $evt = $raw | ConvertFrom-Json

    $command = $null
    if ($evt.tool_input -and $evt.tool_input.PSObject.Properties['command']) {
        $command = [string]$evt.tool_input.command
    }
    if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

    $cwd = if ($evt.PSObject.Properties['cwd'] -and $evt.cwd) { [string]$evt.cwd } else { (Get-Location).Path }
    $result = Get-GuardDecision -Command $command -WorkingDirectory $cwd
    if ($result.Decision) {
        Write-GuardLog ("{0,-5} tool={1} pattern={2} cmd={3}" -f $result.Decision.ToUpper(), $evt.tool_name, $result.Pattern, $command)
        Write-Decision -Decision $result.Decision -Reason $result.Reason
    }
    exit 0
}
catch {
    # A guard that crashes should not block work; log it so a silent hole is visible.
    Write-GuardLog ("ERROR {0}" -f $_.Exception.Message)
    exit 0
}
