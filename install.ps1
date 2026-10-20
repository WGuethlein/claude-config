<#
.SYNOPSIS
    install.ps1 - Points ~/.claude at this repo with directory junctions and an import stub.

.DESCRIPTION
    Name:          install.ps1
    Version:       1.0.0
    Author:        Wyatt Guethlein
    Date:          2026-10-20
    Target:        Both (Windows PowerShell 5.1 and PowerShell 7.6)
    Description:   Links rules/, agents/, hooks/, evals/, and each skill under home/skills/ into
                   ~/.claude as directory junctions, which need no admin rights or Developer Mode.
                   ~/.claude/CLAUDE.md becomes a one-line @import of home/CLAUDE.md, because a file
                   cannot be junctioned. settings/settings.shared.json is merged into the local
                   settings.json rather than linked, since Claude Code writes machine-specific keys there.
    Prerequisites: Repo and ~/.claude on the same machine. No modules. AD required: N.

.PARAMETER ClaudeHome
    The Claude Code config directory. Defaults to $env:USERPROFILE\.claude.

.EXAMPLE
    .\install.ps1 -WhatIf
    Shows what would be linked, moved aside, and merged without changing anything.

.EXAMPLE
    .\install.ps1 -Verbose
#>
#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$ClaudeHome = (Join-Path $env:USERPROFILE '.claude')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Configurable: top-level directories under home/ that are junctioned whole.
$linkedDirs = @('rules', 'agents', 'hooks', 'evals')
# Settings keys owned by the repo; every other key in settings.json stays machine-local.
$sharedKeys = @('permissions', 'hooks', 'enabledPlugins', 'extraKnownMarketplaces')

$repoHome   = Join-Path $PSScriptRoot 'home'
$stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$asideRoot  = "$ClaudeHome.pre-link-$stamp"
$changes    = 0

function Get-JunctionTarget {
    # Returns the resolved target of a junction or symlink, or $null for a real item.
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.LinkType) { return $null }
    # Target is string[] on 5.1 and string on 7.x; normalize to the first entry.
    return (@($item.Target)[0]).TrimEnd('\')
}

function Set-Junction {
    # Creates or repairs a junction at $Path pointing to $Target. Real items are moved aside, not deleted.
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path, [string]$Target)
    if (Test-Path -LiteralPath $Path) {
        $current = Get-JunctionTarget -Path $Path
        if ($current -and ($current -eq $Target.TrimEnd('\'))) {
            Write-Verbose "OK      $Path -> $Target"
            return
        }
        if ($PSCmdlet.ShouldProcess($Path, "Move aside to $asideRoot")) {
            if (-not (Test-Path $asideRoot)) { New-Item -ItemType Directory -Path $asideRoot | Out-Null }
            if ($current) {
                # Wrong link: remove the link only; the target's contents are untouched.
                (Get-Item -LiteralPath $Path -Force).Delete()
            } else {
                $relative = $Path.Substring($ClaudeHome.Length).TrimStart('\')
                $dest = Join-Path $asideRoot $relative
                New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
                Move-Item -LiteralPath $Path -Destination $dest
            }
        }
    }
    if ($PSCmdlet.ShouldProcess($Path, "Create junction to $Target")) {
        New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
        Write-Output "LINKED  $Path -> $Target"
    }
    $script:changes++
}

# Directory junctions.
foreach ($dir in $linkedDirs) {
    Set-Junction -Path (Join-Path $ClaudeHome $dir) -Target (Join-Path $repoHome $dir)
}

# Skills are linked one by one so third-party skills in ~/.claude/skills are left alone.
$skillsDir = Join-Path $ClaudeHome 'skills'
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir | Out-Null }
foreach ($skill in Get-ChildItem -Path (Join-Path $repoHome 'skills') -Directory) {
    Set-Junction -Path (Join-Path $skillsDir $skill.Name) -Target $skill.FullName
}

# CLAUDE.md import stub. Forward slashes keep the @import path unambiguous.
$stubPath = Join-Path $ClaudeHome 'CLAUDE.md'
$stub = "@" + ((Join-Path $repoHome 'CLAUDE.md') -replace '\\', '/')
$existing = if (Test-Path $stubPath) { (Get-Content -LiteralPath $stubPath -Raw).Trim() } else { '' }
if ($existing -ne $stub) {
    if ($existing -and $PSCmdlet.ShouldProcess($stubPath, "Move aside to $asideRoot")) {
        if (-not (Test-Path $asideRoot)) { New-Item -ItemType Directory -Path $asideRoot | Out-Null }
        Move-Item -LiteralPath $stubPath -Destination (Join-Path $asideRoot 'CLAUDE.md')
    }
    if ($PSCmdlet.ShouldProcess($stubPath, "Write import stub '$stub'")) {
        Set-Content -LiteralPath $stubPath -Value $stub -Encoding Ascii
        Write-Output "STUB    $stubPath -> $stub"
    }
    $changes++
} else {
    Write-Verbose "OK      $stubPath"
}

# Merge shared settings keys into the local settings.json, backing it up first.
$settingsPath = Join-Path $ClaudeHome 'settings.json'
$shared = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'settings\settings.shared.json') -Raw | ConvertFrom-Json
$local  = if (Test-Path $settingsPath) { Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json } else { New-Object PSObject }
$settingsChanged = $false
foreach ($key in $sharedKeys) {
    # Compare per key: Add-Member -Force reorders properties, so a whole-object compare always differs.
    $currentValue = if ($local.PSObject.Properties[$key]) { $local.$key | ConvertTo-Json -Depth 20 -Compress } else { '' }
    if ($currentValue -ne ($shared.$key | ConvertTo-Json -Depth 20 -Compress)) {
        $local | Add-Member -NotePropertyName $key -NotePropertyValue $shared.$key -Force
        $settingsChanged = $true
    }
}
if ($settingsChanged) {
    if ($PSCmdlet.ShouldProcess($settingsPath, "Merge keys: $($sharedKeys -join ', ')")) {
        if (Test-Path $settingsPath) { Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak-$stamp" }
        # WriteAllText with a BOM-less encoder: 5.1's Set-Content -Encoding UTF8 adds a BOM.
        [System.IO.File]::WriteAllText($settingsPath, ($local | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))
        Write-Output "MERGED  $settingsPath ($($sharedKeys -join ', '))"
    }
    $changes++
} else {
    Write-Verbose "OK      $settingsPath"
}

if ($changes -eq 0) { Write-Output 'No changes: ~/.claude already matches the repo.' }
elseif (Test-Path $asideRoot) { Write-Output "Replaced items were moved to $asideRoot" }
