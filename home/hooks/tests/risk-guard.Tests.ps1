<#
.SYNOPSIS
    Pester 5 tests for risk-guard.ps1: a table of commands it must deny, ask on, and leave alone.
.DESCRIPTION
    Each case passes a command string to Get-GuardDecision; nothing in the table is executed.
    The script-content cases write throwaway .ps1 files to TestDrive and only read them.
    Run with: Invoke-Pester -Path <this file>   (Windows PowerShell 5.1 or 7.x, Pester 5)
#>

BeforeAll {
    $guard = Join-Path (Split-Path $PSScriptRoot -Parent) 'risk-guard.ps1'
    if (Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'risk-guard.v2.ps1')) {
        $guard = Join-Path (Split-Path $PSScriptRoot -Parent) 'risk-guard.v2.ps1'
    }
    . $guard
}

Describe 'Get-GuardDecision' {
    It 'denies <Command>' -ForEach @(
        @{ Command = 'Remove-ADUser -Identity jdoe' }
        @{ Command = 'Get-ADUser jdoe | Remove-ADUser -Confirm:$false' }
        @{ Command = 'powershell -Command "Remove-ADComputer -Identity PC01"' }
        @{ Command = 'Remove-Mailbox -Identity shared1' }
        @{ Command = "Invoke-MgGraphRequest -Uri /v1.0/users/x -Method DELETE" }
        @{ Command = 'Format-Volume -DriveLetter D' }
        @{ Command = 'Remove-Item -Path \\server\share\dir -Recurse' }
    ) {
        (Get-GuardDecision -Command $Command).Decision | Should -Be 'deny'
    }

    It 'asks on <Command>' -ForEach @(
        @{ Command = 'Set-ADUser jdoe -Title Engineer' }
        @{ Command = 'Disable-ADAccount -Identity jdoe' }
        @{ Command = '$r = Add-ADGroupMember -Identity G1 -Members jdoe' }
        @{ Command = 'Move-ADObject -Identity x -TargetPath y' }
        @{ Command = 'Restart-Service Spooler' }
        @{ Command = 'Invoke-Pester -Path .\tests' }
        @{ Command = 'Invoke-Expression $code' }
        @{ Command = 'iex (Get-Content x.txt -Raw)' }
        @{ Command = 'powershell.exe -NoProfile -EncodedCommand SQBFAFgA' }
        @{ Command = 'Invoke-Command -ComputerName DC1 -ScriptBlock { hostname }' }
        @{ Command = 'powershell -NoProfile -File C:\temp\do-thing.ps1' }
        @{ Command = '& .\Disable-Stale.ps1 -Execute' }
        @{ Command = '.\Disable-Stale.ps1' }
        @{ Command = '. .\helpers.ps1' }
    ) {
        (Get-GuardDecision -Command $Command).Decision | Should -Be 'ask'
    }

    It 'stays silent on <Command>' -ForEach @(
        @{ Command = 'Get-ADUser -Filter * -SearchBase "OU=Test"' }
        @{ Command = 'Get-Command -Name Remove-ADGroup, Add-ADGroup' }
        @{ Command = 'for f in Functions/Remove-ADGroup.ps1 Functions/Add-ADGroup.ps1; do wc -l $f; done' }
        @{ Command = 'git log --oneline -5' }
        @{ Command = 'cat >> OPERATIONS_LOG.md <<EOF' + "`n" + 'risk guard denied Remove-ADUser in a log line' + "`nEOF" }
        @{ Command = 'Select-String -Path *.ps1 -Pattern "Disable-ADAccount"' }
    ) {
        (Get-GuardDecision -Command $Command).Decision | Should -BeNullOrEmpty
    }

    It 'names write cmdlets found inside a script it is asked to run' {
        Set-Content -Path (Join-Path $TestDrive 'Disable-Stale.ps1') -Value 'Get-ADComputer -Filter *; Disable-ADAccount -Identity $c; Set-ADComputer $c -Description x'
        $result = Get-GuardDecision -Command '& .\Disable-Stale.ps1' -WorkingDirectory $TestDrive
        $result.Decision | Should -Be 'ask'
        $result.Reason | Should -Match 'Disable-ADAccount'
        $result.Reason | Should -Match 'Set-ADComputer'
    }

    It 'names write cmdlets in scripts next to a Pester test path' {
        $dir = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'proj')
        Set-Content -Path (Join-Path $dir 'Remove-Departed.ps1') -Value 'Invoke-MgGraphRequest -Uri $u -Method DELETE'
        Set-Content -Path (Join-Path $dir 'Remove-Departed.Tests.ps1') -Value 'Describe x { It y { } }'
        $result = Get-GuardDecision -Command 'Invoke-Pester -Path .\proj\Remove-Departed.Tests.ps1' -WorkingDirectory $TestDrive
        $result.Decision | Should -Be 'ask'
        $result.Reason | Should -Match 'Invoke-MgGraphRequest'
    }

    It 'reports no write cmdlets for a read-only script' {
        Set-Content -Path (Join-Path $TestDrive 'Get-Report.ps1') -Value 'Get-ADUser -Filter * | Export-Csv out.csv'
        $result = Get-GuardDecision -Command '& .\Get-Report.ps1' -WorkingDirectory $TestDrive
        $result.Decision | Should -Be 'ask'
        $result.Reason | Should -Match 'No directory, mailbox, or Graph write cmdlets'
    }
}
