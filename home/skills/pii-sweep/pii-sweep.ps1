<#
.SYNOPSIS
    pii-sweep.ps1 - scans text under a path for real-data leakage: digit-shaped
    identifiers, plus prose that claims a nearby value is real, plus documents
    that redact a value in one place and print it in another.

.DESCRIPTION
    Name:          pii-sweep.ps1
    Version:       1.1.0
    Author:        Wyatt Guethlein
    Date:          2026-09-02
    Description:   A pre-push/pre-commit check. The prior ad hoc sweep on the
                   benefit-invoice-reconciliation branch classified digit-
                   shaped hits by whether they "traced to an invented fixture
                   set" and never read the surrounding prose, so a spec table
                   headed "Verified ... by reading the real workbook" cleared
                   twice with a real SSN fragment and member ID inside it.
                   v1.1.0: the original digit patterns (dashed SSN, bare
                   nine-digit run) missed a bare SSN-last-4 - a 3-or-4-digit
                   literal, leading zero often dropped - which is the higher-
                   sensitivity field of the two and the one that mattered most
                   in the real incident. Added SSN-context-aware detection for
                   short digit literals, and stopped reporting CLEAN when
                   realness or redaction language is present but did not pair
                   with a digit hit - that was denying what a reader could see
                   on the screen.
    Prerequisites: Windows PowerShell 5.1 or later. git on PATH only if
                   -DiffRange is used. No modules required.
    Usage:         powershell -NoProfile -File pii-sweep.ps1 -Path C:\Projects\Dayforce
                   powershell -NoProfile -File pii-sweep.ps1 -Path C:\Projects\Dayforce -DiffRange "main...HEAD"

.NOTES
    Exit codes: 0 = no findings at all - no digit-shaped literal, no realness
    language, no redaction claim anywhere in scope. 1 = some finding present
    (digit-shaped literal, realness language, or redaction claim) but nothing
    escalated - needs manual triage, not a pass. 2 = at least one HIGH
    escalation (realness language or a redaction contradiction sharing a file
    with a digit-shaped literal) - treat as a hard stop, not a judgment call.
    3 = the sweep itself errored; treat as a failure to clear, not a pass.
    This script never classifies a value as "clearly invented" on its own; it
    surfaces what needs a human or a reviewing agent to look at.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [string]$DiffRange,

    [Parameter(Mandatory = $false)]
    [int]$ContextLines = 3
)

# --- Configurable variables --------------------------------------------------

# Directories never scanned: build output, git internals, and carrier
# reference workbooks. Those workbooks are real data by design and are the
# source of truth this sweep exists to keep OUT of source/tests/docs, not a
# scan target themselves.
$excludeDirPatterns = @('\\bin\\', '\\obj\\', '\\\.git\\', '\\reference\\')

# Text-file extensions worth scanning. Binary workbook formats are excluded
# deliberately - they are not read as text and are not the leak target here.
$includeExtensions = @('.cs', '.md', '.json', '.txt', '.csv', '.yml', '.yaml', '.xml')

# Digit-shaped patterns: SSN-dashed, bare nine-digit runs. Deliberately does
# NOT try to classify a hit as "fixture-looking" - that judgment is exactly
# what let a real value through twice.
$digitPatterns = @(
    '\b\d{3}-\d{2}-\d{4}\b',
    '\b\d{9}\b'
)

# A 3-or-4-digit literal (leading zero included, since that is exactly what
# a spreadsheet cell read as a number drops from a Last-4) is too common to
# flag globally - years, row counts, dollar amounts are everywhere. It is
# only flagged when SSN-ish language sits on the same line or within about
# two lines of it. This is what catches an SSN-last-4 with no accompanying
# nine-digit member ID nearby - the exact gap in the value that leaked here.
$ssnContextDigitPattern = '\b\d{3,4}\b'
$ssnContextPhrases = @(
    'ssn', 'last 4', 'last four', 'ssnlast4', 'ssn_last4', 'last 4 ssn'
)
$ssnContextWindow = 2

# Phrases that claim a nearby value is real, drawn from the incident: a spec
# table headed "Verified 2026-08-26 by reading the real workbook" cleared
# with real values inside it.
$realnessPhrases = @(
    'real workbook', 'verified by reading', 'reading the real', 'actual value',
    'from the live', 'as it appears in', 'genuine', 'confirmed real',
    'real member', 'real ssn', 'live census', 'live workbook'
)

# Phrases that claim identifiers are withheld. A file carrying one of these
# AND a digit-shaped literal has redacted in one place and printed in
# another - exactly what happened here.
$redactionPhrases = @(
    'not reproduced in this repository', 'deliberately not reproduced',
    'redacted', 'not included in this repository', 'withheld from this repository'
)

# --- Functions ---------------------------------------------------------------

function Get-ScanFiles {
    param([string]$RootPath, [string]$Range)

    if ($Range) {
        Push-Location $RootPath
        try {
            $changed = git diff --name-only $Range 2>$null
        } finally {
            Pop-Location
        }
        $files = @()
        foreach ($rel in $changed) {
            if ([string]::IsNullOrWhiteSpace($rel)) { continue }
            $full = Join-Path $RootPath $rel
            if (Test-Path -Path $full -PathType Leaf) { $files += Get-Item -Path $full }
        }
        return $files
    }

    return Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue
}

function Test-Excluded {
    param([string]$FullName)
    foreach ($pat in $excludeDirPatterns) {
        if ($FullName -imatch $pat) { return $true }
    }
    return $false
}

# --- Main ----------------------------------------------------------------

try {
    $resolvedPath = (Resolve-Path -Path $Path -ErrorAction Stop).ProviderPath
    $allFiles = Get-ScanFiles -RootPath $resolvedPath -Range $DiffRange

    $scanFiles = @()
    foreach ($f in $allFiles) {
        if (Test-Excluded -FullName $f.FullName) { continue }
        if ($includeExtensions -notcontains $f.Extension.ToLowerInvariant()) { continue }
        $scanFiles += $f
    }

    $digitHits = @()      # per-file line hits of digit shapes
    $realnessHits = @()   # per-file line hits of realness language
    $redactionHits = @()  # per-file line hits of redaction claims

    foreach ($f in $scanFiles) {
        $lines = Get-Content -Path $f.FullName -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        if ($lines -isnot [System.Array]) { $lines = @($lines) }

        # Precompute which lines carry SSN-ish language, so the windowed
        # lookup below does not re-scan phrases per candidate digit.
        $contextLineFlags = New-Object bool[] ($lines.Count)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($cp in $ssnContextPhrases) {
                if ($lines[$i] -imatch [regex]::Escape($cp)) { $contextLineFlags[$i] = $true; break }
            }
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $lineNo = $i + 1

            foreach ($p in $digitPatterns) {
                if ($line -match $p) {
                    $digitHits += [PSCustomObject]@{ File = $f.FullName; Line = $lineNo; Text = $line.Trim() }
                }
            }
            foreach ($p in $realnessPhrases) {
                if ($line -imatch [regex]::Escape($p)) {
                    $realnessHits += [PSCustomObject]@{ File = $f.FullName; Line = $lineNo; Text = $line.Trim() }
                }
            }
            foreach ($p in $redactionPhrases) {
                if ($line -imatch [regex]::Escape($p)) {
                    $redactionHits += [PSCustomObject]@{ File = $f.FullName; Line = $lineNo; Text = $line.Trim() }
                }
            }

            # SSN-context short digit literal (e.g. a Last-4, with or without
            # a leading zero). Only counted when SSN-ish language is on this
            # line or within $ssnContextWindow lines of it.
            if ($line -match $ssnContextDigitPattern) {
                $winStart = $i - $ssnContextWindow
                if ($winStart -lt 0) { $winStart = 0 }
                $winEnd = $i + $ssnContextWindow
                if ($winEnd -gt ($lines.Count - 1)) { $winEnd = $lines.Count - 1 }

                $hasContext = $false
                for ($w = $winStart; $w -le $winEnd; $w++) {
                    if ($contextLineFlags[$w]) { $hasContext = $true; break }
                }

                if ($hasContext) {
                    $digitHits += [PSCustomObject]@{ File = $f.FullName; Line = $lineNo; Text = $line.Trim() }
                }
            }
        }
    }

    # HIGH escalation 1: a file carrying BOTH realness language and a
    # digit-shaped literal - the exact shape of the incident.
    $realnessFiles = $realnessHits | Select-Object -ExpandProperty File -Unique
    $digitFiles    = $digitHits    | Select-Object -ExpandProperty File -Unique
    $escalation1Files = $realnessFiles | Where-Object { $digitFiles -contains $_ }

    # HIGH escalation 2: a file that claims redaction AND prints a
    # digit-shaped literal.
    $redactionFiles = $redactionHits | Select-Object -ExpandProperty File -Unique
    $escalation2Files = $redactionFiles | Where-Object { $digitFiles -contains $_ }

    Write-Output "=== PII sweep: $($scanFiles.Count) files scanned ==="
    Write-Output ""

    if ($escalation1Files.Count -gt 0) {
        Write-Output "--- HIGH: realness language + digit-shaped literal in the same file ---"
        foreach ($file in $escalation1Files) {
            Write-Output "File: $file"
            $realnessHits | Where-Object { $_.File -eq $file } | ForEach-Object { Write-Output ("  realness  L{0}: {1}" -f $_.Line, $_.Text) }
            $digitHits    | Where-Object { $_.File -eq $file } | ForEach-Object { Write-Output ("  digit     L{0}: {1}" -f $_.Line, $_.Text) }
        }
        Write-Output ""
    }

    if ($escalation2Files.Count -gt 0) {
        Write-Output "--- HIGH: redaction claim + digit-shaped literal in the same file ---"
        foreach ($file in $escalation2Files) {
            Write-Output "File: $file"
            $redactionHits | Where-Object { $_.File -eq $file } | ForEach-Object { Write-Output ("  redaction L{0}: {1}" -f $_.Line, $_.Text) }
            $digitHits     | Where-Object { $_.File -eq $file } | ForEach-Object { Write-Output ("  digit     L{0}: {1}" -f $_.Line, $_.Text) }
        }
        Write-Output ""
    }

    # Realness/redaction language that did NOT pair with a digit hit in the
    # same file still gets reported - a summary that says "nothing found"
    # while a reader can see "reading the real workbook" on line 3 is the
    # same class of defect as a doc comment contradicting its own code.
    $realnessOnlyHits = $realnessHits | Where-Object { $escalation1Files -notcontains $_.File }
    if ($realnessOnlyHits.Count -gt 0) {
        Write-Output "--- Realness language found (no digit-shaped literal paired with it in this file) ---"
        $realnessOnlyHits | ForEach-Object { Write-Output ("  {0}:{1}: {2}" -f $_.File, $_.Line, $_.Text) }
        Write-Output ""
    }

    $redactionOnlyHits = $redactionHits | Where-Object { $escalation2Files -notcontains $_.File }
    if ($redactionOnlyHits.Count -gt 0) {
        Write-Output "--- Redaction claims found (no digit-shaped literal paired with it in this file) ---"
        $redactionOnlyHits | ForEach-Object { Write-Output ("  {0}:{1}: {2}" -f $_.File, $_.Line, $_.Text) }
        Write-Output ""
    }

    if ($digitHits.Count -gt 0) {
        Write-Output "--- Digit-shaped literals found (manual triage required - do not auto-clear) ---"
        $digitHits | ForEach-Object { Write-Output ("  {0}:{1}: {2}" -f $_.File, $_.Line, $_.Text) }
        Write-Output ""
    }

    $totalFindings = $digitHits.Count + $realnessHits.Count + $redactionHits.Count

    if ($escalation1Files.Count -gt 0 -or $escalation2Files.Count -gt 0) {
        Write-Output "RESULT: FAIL - HIGH escalation(s) found. Treat as real until proven otherwise."
        exit 2
    } elseif ($totalFindings -gt 0) {
        Write-Output "RESULT: NEEDS TRIAGE - digit-shaped literal(s) and/or realness/redaction language found, none paired into a HIGH escalation. Confirm each by tracing to its source before clearing - do not report this as clean."
        exit 1
    } else {
        Write-Output "RESULT: CLEAN - no digit-shaped literals and no realness/redaction language found."
        exit 0
    }
}
catch {
    Write-Output "PII SWEEP ERROR: $($_.Exception.Message)"
    exit 3
}
