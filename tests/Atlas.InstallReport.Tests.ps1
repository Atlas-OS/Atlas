BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:ReportScript = Join-Path $script:AtlasTestRepoRoot 'tools\dev\Get-AtlasInstallReport.ps1'
    $errors = $null
    $script:ReportAst = [Management.Automation.Language.Parser]::ParseFile($script:ReportScript, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in 'Add-Line', 'Add-Summary', 'Add-Section', 'Get-InstallTransactionLine') {
        $function = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
            }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    $script:Utf8 = New-Object System.Text.UTF8Encoding($false)
}

Describe 'Install report sections' {
    BeforeEach {
        $script:report = New-Object System.Collections.Generic.List[string]
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:PartialReport = Join-Path $TestDrive 'machine-report.partial.txt'
        Remove-Item -LiteralPath $script:PartialReport -Force -ErrorAction SilentlyContinue
        Mock Write-Host {}
    }

    It 'appends each finished section, including a failed one, to the partial report' {
        Add-Section -Title '1. First' -Collector { 'first line' }
        Add-Section -Title '2. Broken' -Collector { throw 'collector failed' }
        Add-Section -Title '3. Empty' -Collector { }

        $partial = [IO.File]::ReadAllLines($script:PartialReport)
        ($partial -join "`n") | Should -Be ($script:report -join "`n")
        $partial | Should -Contain 'first line'
        $partial | Should -Contain 'COLLECTION FAILED: collector failed'
        $partial | Should -Contain '(nothing to report)'
        $script:Summary | Should -HaveCount 1
    }

    It 'keeps collecting when the partial report can no longer be updated' {
        Add-Section -Title '1. First' -Collector { 'first line' }
        # Another process holds the file, as antivirus or backup software may.
        $lock = [IO.File]::Open($script:PartialReport, 'Open', 'Read', 'Read')
        try {
            { Add-Section -Title '2. Second' -Collector { 'second line' } } | Should -Not -Throw
            { Add-Section -Title '3. Third' -Collector { 'third line' } } | Should -Not -Throw
        }
        finally { $lock.Dispose() }

        $script:report | Should -Contain 'second line'
        $script:report | Should -Contain 'third line'
        $script:Summary | Should -HaveCount 1
        $script:Summary[0] | Should -BeLike "The partial report could not be updated after section '2. Second':*"
        $script:PartialReport | Should -BeNullOrEmpty
        $partial = [IO.File]::ReadAllLines((Join-Path $TestDrive 'machine-report.partial.txt'))
        $partial | Should -Contain 'first line'
        $partial | Should -Not -Contain 'third line'
    }

    It 'writes no partial report when none is requested' {
        $script:PartialReport = $null

        Add-Section -Title '1. First' -Collector { 'first line' }

        $script:report | Should -Contain 'first line'
        Get-ChildItem -LiteralPath $TestDrive -Filter '*.partial.txt' | Should -BeNullOrEmpty
        $script:Summary | Should -HaveCount 0
    }
}

Describe 'Install report limits' {
    It 'limits every event log read' {
        $reads = @($script:ReportAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                        $node.GetCommandName() -eq 'Get-WinEvent' -and
                        $node.Extent.Text -notmatch '-ListLog'
                }, $true))
        $reads | Should -Not -BeNullOrEmpty
        foreach ($read in $reads) {
            $read.Extent.Text | Should -Match '-MaxEvents'
        }
    }
}

Describe 'Install report event log section' {
    BeforeAll {
        $section = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Add-Section' -and $node.Extent.Text -match "-Title '10\."
            }, $true)
        $script:EventCollector = $section.CommandElements[-1].ScriptBlock.GetScriptBlock()
    }
    BeforeEach {
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:InstalledAt = [datetime]'2026-01-01'
        $script:EventListCount = 10
        # Newest first, as Get-WinEvent returns them.
        $script:Events = @(
            [pscustomobject]@{ Level = 2; TimeCreated = [datetime]'2026-09-20'; ProviderName = 'disk'; Id = 7; Message = 'bad block'; LevelDisplayName = 'Error' },
            [pscustomobject]@{ Level = 3; TimeCreated = [datetime]'2026-09-19'; ProviderName = 'Tcpip'; Id = 4199; Message = 'conflict'; LevelDisplayName = 'Warning' },
            [pscustomobject]@{ Level = 3; TimeCreated = [datetime]'2026-09-18'; ProviderName = 'Tcpip'; Id = 4199; Message = 'conflict'; LevelDisplayName = 'Warning' }
        )
        $script:AppxLog = 'Microsoft-Windows-AppXDeploymentServer/Operational'
        $script:AppxEvents = @()
        Mock Get-WinEvent { $script:Events } -ParameterFilter { $FilterHashtable.LogName -ne $script:AppxLog }
        Mock Get-WinEvent { $script:AppxEvents } -ParameterFilter { $FilterHashtable.LogName -eq $script:AppxLog }
    }

    It 'reports AppX deployment errors, the reason behind a failed Store update' {
        $script:EventReadLimit = 5000
        $script:AppxEvents = @(
            [pscustomobject]@{ Level = 2; TimeCreated = [datetime]'2026-09-21'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 404; Message = 'AppX Deployment operation failed with error 0x80073CF9'; LevelDisplayName = 'Error' }
        )
        $lines = & $script:EventCollector
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable.LogName -eq $script:AppxLog -and (@($FilterHashtable.Level) -join ',') -eq '1,2'
        }
        $script:Summary | Should -HaveCount 3
        $script:Summary[2] | Should -Match "^$([regex]::Escape($script:AppxLog)) log: 1 error"
        ($lines -join "`n") | Should -Match 'operation failed with error 0x80073CF9'
    }

    It 'counts errors for the whole window when every event was read' {
        $script:EventReadLimit = 5000
        $lines = & $script:EventCollector
        $script:Summary | Should -HaveCount 2
        $script:Summary[0] | Should -Match '^System log: 1 error'
        $script:Summary[0] | Should -BeLike "*$($script:InstalledAt.AddMinutes(-30))*"
        $script:Summary[0] | Should -Not -Match 'newest'
        ($lines -join "`n") | Should -Not -Match 'only the newest'
    }

    It 'says how far back it read when the limit cut the window short' {
        $script:EventReadLimit = 3
        $oldest = [datetime]'2026-09-18'
        $lines = & $script:EventCollector
        $note = @($lines | Where-Object { $_ -like '*newest 3*' })
        $note | Should -Not -BeNullOrEmpty
        $note[0] | Should -BeLike "*$oldest*not counted*"
        $script:Summary | Should -HaveCount 2
        $script:Summary[0] | Should -Match '^System log: 1 error'
        $script:Summary[0] | Should -BeLike "*newest 3*$oldest*not read*"
        # Without an error among them, the summary still says the window was not read in full.
        $script:Events = @($script:Events | ForEach-Object { $_.Level = 3; $_ })
        $script:Summary.Clear()
        $null = & $script:EventCollector
        $script:Summary[1] | Should -BeLike 'Application log: 0 error or critical event(s) among the newest 3 *'
    }
}

Describe 'Install report install state section' {
    BeforeAll {
        $section = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Add-Section' -and $node.Extent.Text -match "-Title '2\."
            }, $true)
        $script:StateCollector = $section.CommandElements[-1].ScriptBlock.GetScriptBlock()
        function New-TransactionJson {
            param([string]$Status, [string]$Mode, [string[]]$Steps = @(), [string]$LastError)
            [pscustomobject]@{
                schemaVersion = 1; targetVersion = '0.6.0'; transactionId = [guid]::NewGuid().ToString('D')
                status = $Status; mode = $Mode; isOobe = $false; options = @('defender-enable')
                userSid = $null; userSessionId = $null; captureNonce = 'nonce'
                completedSteps = @($Steps); lastError = $(if ($LastError) { $LastError } else { $null })
            } | ConvertTo-Json -Compress
        }
    }
    BeforeEach {
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:atlasState = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:statePath = Join-Path $script:atlasState 'state.json'
        $script:installRoot = Join-Path $script:atlasState 'Install'
        New-Item -ItemType Directory -Path $script:installRoot -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'last.json'), (New-TransactionJson -Status Completed -Mode Fresh -Steps 'phase-a', 'phase-b'))
    }

    It 'reports the failed transaction in active.json besides the last completed one' {
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json'), (New-TransactionJson -Status Running -Mode Reapply -Steps 'phase-a' -LastError 'Step phase-b failed.'))

        $lines = & $script:StateCollector

        $script:Summary | Should -Contain 'Unfinished install transaction: Reapply of 0.6.0, status Running, 1 step(s) completed, lastError Step phase-b failed.'
        $script:Summary | Should -Contain 'Last completed install transaction: Fresh of 0.6.0, 2 step(s) completed.'
        $lines | Should -Contain '  lastError         : Step phase-b failed.'
    }

    It 'falls back to the backup when active.json is unreadable' {
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json'), '{ not json')
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json.bak'), (New-TransactionJson -Status Running -Mode Fresh -LastError 'Step phase-a failed.'))

        $lines = & $script:StateCollector

        @($lines | Where-Object { $_ -like '*active.json is unreadable:*' }) | Should -HaveCount 1
        $lines | Should -Contain ('{0,-20}: {1}' -f 'active.json.bak', (Join-Path $script:installRoot 'active.json.bak'))
        $script:Summary | Should -Contain 'Unfinished install transaction: Fresh of 0.6.0, status Running, 0 step(s) completed, lastError Step phase-a failed.'
    }

    It 'falls back to the backup when active.json is empty' {
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json'), '')
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json.bak'), (New-TransactionJson -Status Running -Mode Fresh -LastError 'Step phase-a failed.'))

        $lines = & $script:StateCollector

        @($lines | Where-Object { $_ -like '*active.json is unreadable:*' }) | Should -HaveCount 1
        $lines | Should -Contain ('{0,-20}: {1}' -f 'active.json.bak', (Join-Path $script:installRoot 'active.json.bak'))
        $script:Summary | Should -Contain 'Last completed install transaction: Fresh of 0.6.0, 2 step(s) completed.'
    }

    It 'keeps the rest of the section when last.json is empty' {
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'active.json'), (New-TransactionJson -Status Running -Mode Reapply -Steps 'phase-a' -LastError 'Step phase-b failed.'))
        [IO.File]::WriteAllText((Join-Path $script:installRoot 'last.json'), '')

        $lines = & $script:StateCollector

        $lines | Should -Contain '  lastError         : Step phase-b failed.'
        @($lines | Where-Object { $_ -like '*last.json is unreadable: It is empty or not a JSON object.' }) | Should -HaveCount 1
    }
}

Describe 'Install report health check section' {
    BeforeAll {
        $section = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Add-Section' -and $node.Extent.Text -match "-Title '4\."
            }, $true)
        $script:HealthCollector = $section.CommandElements[-1].ScriptBlock.GetScriptBlock()
    }

    It 'records a health check that cannot run, with its stderr, instead of failing the section' {
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:atlasModules = Join-Path $TestDrive 'AtlasModules'
        $entry = Join-Path $script:atlasModules 'Scripts\Entry'
        New-Item -ItemType Directory -Path $entry -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $entry 'Test-AtlasHealth.ps1') -Value @(
            "Write-Output 'checking'"
            "[Console]::Error.WriteLine('Atlas is not installed on this machine.')"
            'exit 2'
        )
        # As the report runs it.
        $ErrorActionPreference = 'Stop'

        $lines = @(& $script:HealthCollector)

        $lines | Should -Contain 'checking'
        $lines | Should -Contain 'Atlas is not installed on this machine.'
        $lines | Should -Contain 'Health check exit code: 2 (the check could not run)'
        $script:Summary | Should -Contain 'Health check: the check could not run (exit code 2).'
    }
}
