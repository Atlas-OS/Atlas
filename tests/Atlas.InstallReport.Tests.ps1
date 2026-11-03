BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:ReportScript = Join-Path $script:AtlasTestRepoRoot 'tools\dev\Get-AtlasInstallReport.ps1'
    $errors = $null
    $script:ReportAst = [Management.Automation.Language.Parser]::ParseFile($script:ReportScript, [ref]$null, [ref]$errors)
    if ($errors) { throw ($errors | Out-String) }
    foreach ($name in 'Add-Line', 'Add-Summary', 'Add-Section', 'Get-InstallTransactionLine', 'Get-RegistryValueOrNull',
        'Get-EventWindow', 'Get-AppxRemovalPattern', 'Get-RecordedInstallOption', 'Test-AppxPatternMatch',
        'Get-AppxAllUserStorePackage', 'Get-AtlasServicingPackageLine') {
        $function = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
            }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    $script:Utf8 = New-Object System.Text.UTF8Encoding($false)

    function Find-ReportSection {
        param([Parameter(Mandatory = $true)][string]$Number)
        $title = "-Title '$Number\."
        $section = $script:ReportAst.Find({
                param($node)
                $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Add-Section' -and $node.Extent.Text -match $title
            }, $true)
        $section.CommandElements[-1].ScriptBlock.GetScriptBlock()
    }

    # An installed Atlas.Appx removal list, as the report reads it from source. Option
    # maps a pattern to the option that gates it; WarnOnly patterns have IgnoreErrors.
    function New-RemovalModule {
        param([Parameter(Mandatory = $true)][string]$Root, [string[]]$Name, [hashtable]$Option = @{}, [string[]]$WarnOnly = @())
        $domain = Join-Path $Root 'Scripts\Modules\Atlas.Appx\Domain'
        New-Item -ItemType Directory -Path $domain -Force | Out-Null
        $entries = @($Name | ForEach-Object {
                $gate = if ($Option.ContainsKey($_)) { "'$($Option[$_])'" } else { '$null' }
                $ignore = if ($WarnOnly -contains $_) { '$true' } else { '$false' }
                "        [pscustomobject]@{ Name = '$_'; Option = $gate; IgnoreErrors = $ignore }"
            })
        Set-Content -LiteralPath (Join-Path $domain 'Removal.ps1') -Value (
            @('function Get-AtlasAppxRemovalDefinition {', '    return @(') + $entries + @('    )', '}', '$other = @{ Name = ''NotADefinition'' }')
        )
    }
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
        $script:atlasState = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:atlasModules = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        # Newest first, as Get-WinEvent returns them.
        $script:Events = @(
            [pscustomobject]@{ Level = 2; TimeCreated = [datetime]'2026-09-20'; ProviderName = 'disk'; Id = 7; Message = 'bad block'; LevelDisplayName = 'Error' },
            [pscustomobject]@{ Level = 3; TimeCreated = [datetime]'2026-09-19'; ProviderName = 'Tcpip'; Id = 4199; Message = 'conflict'; LevelDisplayName = 'Warning' },
            [pscustomobject]@{ Level = 3; TimeCreated = [datetime]'2026-09-18'; ProviderName = 'Tcpip'; Id = 4199; Message = 'conflict'; LevelDisplayName = 'Warning' }
        )
        $script:AppxLog = 'Microsoft-Windows-AppXDeploymentServer/Operational'
        $script:AppxEvents = @()
        Mock Get-WinEvent { $script:Events } -ParameterFilter { $FilterHashtable.LogName -ne $script:AppxLog }
        Mock Get-WinEvent {
            @($script:AppxEvents | Where-Object { @($FilterHashtable.Level) -contains $_.Level })
        } -ParameterFilter { $FilterHashtable.LogName -eq $script:AppxLog }
    }

    It 'reports AppX deployment errors, the reason behind a failed Store update' {
        $script:EventReadLimit = 5000
        $script:AppxEvents = @(
            [pscustomobject]@{ Level = 2; TimeCreated = [datetime]'2026-09-21'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 404; Message = 'AppX Deployment operation failed with error 0x80073CF9'; LevelDisplayName = 'Error' }
        )
        $lines = & $script:EventCollector
        # Errors over the whole window; warnings and information, which are many, only
        # over the install, as a removal that leaves a package behind logs no error.
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable.LogName -eq $script:AppxLog -and (@($FilterHashtable.Level) -join ',') -eq '1,2' -and
            -not $FilterHashtable.ContainsKey('EndTime')
        }
        Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
            $FilterHashtable.LogName -eq $script:AppxLog -and (@($FilterHashtable.Level) -join ',') -eq '3,4' -and
            $FilterHashtable.EndTime -eq $script:InstalledAt.AddHours(1)
        }
        $script:Summary | Should -HaveCount 3
        $script:Summary[2] | Should -Match "^$([regex]::Escape($script:AppxLog)) log: 1 error"
        ($lines -join "`n") | Should -Match 'operation failed with error 0x80073CF9'
        $lines | Should -Contain "-- $script:AppxLog, warnings and information over the install until $($script:InstalledAt.AddHours(1)) --"
    }

    It 'starts the window when an unfinished install began, not at this boot' {
        $script:EventReadLimit = 5000
        $script:InstalledAt = $null
        $active = Join-Path $script:atlasState 'Install\active.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $active) -Force | Out-Null
        Set-Content -LiteralPath $active -Value '{}'
        $began = [datetime]'2026-10-28 17:07:59'
        (Get-Item -LiteralPath $active).CreationTime = $began

        $lines = & $script:EventCollector

        $lines[0] | Should -BeLike "Window: since $began, the start of the unfinished install *"
        Should -Invoke Get-WinEvent -Times 4 -Exactly -ParameterFilter { $FilterHashtable.StartTime -eq $began }
        # The install may still be going on, so its AppX activity has no end yet.
        Should -Invoke Get-WinEvent -Times 0 -Exactly -ParameterFilter { $FilterHashtable.ContainsKey('EndTime') }
    }

    It 'says when the newest warnings and information did not reach back to the install' {
        $script:EventReadLimit = 2
        $script:AppxEvents = @(
            [pscustomobject]@{ Level = 4; TimeCreated = [datetime]'2026-01-01 00:20'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 400; Message = 'one'; LevelDisplayName = 'Information' }
            [pscustomobject]@{ Level = 4; TimeCreated = [datetime]'2026-01-01 00:10'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 400; Message = 'two'; LevelDisplayName = 'Information' }
        )

        $lines = @(& $script:EventCollector)

        $lines | Should -Contain "  (only the newest 2 were read, back to $([datetime]'2026-01-01 00:10'))"
        $script:Summary | Should -Contain "$script:AppxLog log: only the newest 2 warnings and information over the install were read, back to $([datetime]'2026-01-01 00:10')."
    }

    It 'lists each AppX deployment event that names a package Atlas removes' {
        $script:EventReadLimit = 5000
        New-RemovalModule -Root $script:atlasModules -Name 'MSTeams*', 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe', 'Microsoft.ScreenSketch*' `
            -Option @{ 'Microsoft.ScreenSketch*' = 'remove-snipping-tool' }
        $script:AppxEvents = @(
            [pscustomobject]@{
                Level = 4; TimeCreated = [datetime]'2026-10-28 17:26:01'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 400
                Message = 'Deployment Register operation on Package Microsoft.ScreenSketch_11.2409.0.0_x64__8wekyb3d8bbwe finished successfully.'
                LevelDisplayName = 'Information'
                Properties = @([pscustomobject]@{ Value = 'Microsoft.ScreenSketch_11.2409.0.0_x64__8wekyb3d8bbwe' })
            }
            [pscustomobject]@{
                Level = 4; TimeCreated = [datetime]'2026-10-28 17:26:00'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 400
                Message = "Deployment Remove operation with target volume C: on Package MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe`r`n from: (MSTeams.msix) finished successfully."
                LevelDisplayName = 'Information'
                Properties = @([pscustomobject]@{ Value = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe' })
            }
            [pscustomobject]@{
                Level = 4; TimeCreated = [datetime]'2026-10-28 17:25:59'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 400
                Message = 'Deployment Remove operation on Package Contoso.Other_1.0_x64__abc finished successfully.'
                LevelDisplayName = 'Information'
                Properties = @([pscustomobject]@{ Value = 'Contoso.Other_1.0_x64__abc' })
            }
            [pscustomobject]@{
                Level = 3; TimeCreated = [datetime]'2026-10-28 17:25:58'; ProviderName = 'Microsoft-Windows-AppXDeployment-Server'; Id = 431
                Message = 'Removal of Microsoft.MicrosoftEdge.Stable_155.0.4283.60_neutral__8wekyb3d8bbwe was deferred.'
                LevelDisplayName = 'Warning'
                Properties = @([pscustomobject]@{ Value = 'Microsoft.MicrosoftEdge.Stable_155.0.4283.60_neutral__8wekyb3d8bbwe' })
            }
        )

        $lines = @(& $script:EventCollector)

        $start = [array]::IndexOf($lines, '  Events that name a package Atlas removes (newest 2, up to 10):')
        $start | Should -BeGreaterThan 0
        $lines[$start + 1] | Should -Be '    2026-10-28 17:26:00 Information 400: Deployment Remove operation with target volume C: on Package MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe from: (MSTeams.msix) finished successfully.'
        $lines[$start + 2] | Should -BeLike '    2026-10-28 17:25:58 Warning     431: Removal of Microsoft.MicrosoftEdge.Stable_*'
        $lines.Count | Should -Be ($start + 3)
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

    BeforeEach {
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:atlasModules = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:HealthEntry = Join-Path $script:atlasModules 'Scripts\Entry'
        New-Item -ItemType Directory -Path $script:HealthEntry -Force | Out-Null
        $script:HealthCheckSeconds = 60
    }

    It 'records a health check that cannot run, with its stderr, instead of failing the section' {
        Set-Content -LiteralPath (Join-Path $script:HealthEntry 'Test-AtlasHealth.ps1') -Value @(
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

    It 'stops a health check at its time limit and keeps what it wrote' {
        Set-Content -LiteralPath (Join-Path $script:HealthEntry 'Test-AtlasHealth.ps1') -Value @(
            "Write-Output 'checking toggles'"
            'Start-Sleep -Seconds 120'
            "Write-Output 'never reached'"
        )
        $script:HealthCheckSeconds = 3
        $ErrorActionPreference = 'Stop'

        $elapsed = Measure-Command { $script:lines = @(& $script:HealthCollector) }

        $elapsed.TotalSeconds | Should -BeLessThan 20
        $script:lines | Should -Contain 'checking toggles'
        $script:lines | Should -Not -Contain 'never reached'
        $script:lines | Should -Contain "The health check didn't finish within 3 seconds, so it was stopped and drift was not verified."
        $script:Summary | Should -Contain 'Health check: stopped after 3 seconds without a result, so drift was not verified.'
    }
}

Describe 'Install report AppX removal leftovers' {
    BeforeAll {
        $script:AppsCollector = Find-ReportSection -Number 7
    }
    BeforeEach {
        $script:Summary = New-Object System.Collections.Generic.List[string]
        $script:atlasModules = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:atlasState = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:atlasState -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:atlasState 'state.json') -Value '{ "options": [ "uninstall-edge" ] }'
        New-RemovalModule -Root $script:atlasModules -Name 'MSTeams*', 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe' `
            -Option @{ 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe' = 'uninstall-edge' } -WarnOnly 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
        Mock Get-AppxAllUserStorePackage { throw 'The registry fallback ran while elevated.' }
        $script:RegisteredPackages = @(
            [pscustomobject]@{
                Name = 'MSTeams'; PackageFamilyName = 'MSTeams_8wekyb3d8bbwe'
                PackageFullName = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'; Version = '26260.1717.5229.7049'
                Status = 'Ok'; IsBundle = $false; IsPartiallyStaged = $false; NonRemovable = $false; SignatureKind = 'Store'
                PackageUserInformation = @(
                    [pscustomobject]@{
                        UserSecurityId = [pscustomobject]@{ Sid = 'S-1-5-21-1000-1000-1000-1000'; Username = 'S-1-5-21-1000-1000-1000-1000' }
                        InstallState   = 'Installed'
                    }
                )
            }
            [pscustomobject]@{
                Name = 'Contoso.Kept'; PackageFamilyName = 'Contoso.Kept_abc'; PackageFullName = 'Contoso.Kept_1.0_x64__abc'
                Version = '1.0'; Status = 'Ok'; IsBundle = $false; IsPartiallyStaged = $false; NonRemovable = $false
                SignatureKind = 'Store'; PackageUserInformation = @()
            }
        )
        Mock Get-AppxPackage { $script:RegisteredPackages } -ParameterFilter { $AllUsers }
        Mock Get-AppxPackage { @() } -ParameterFilter { -not $AllUsers }
        Mock Get-AppxProvisionedPackage {
            @([pscustomobject]@{
                    DisplayName = 'Microsoft.MicrosoftEdge'; Version = '44.19041.1266.0'
                    PackageName = 'Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe'
                })
        }
    }

    It 'lists every package Atlas removes that any account has, with each account''s install state' {
        $lines = @(& $script:AppsCollector)

        $start = [array]::IndexOf($lines, '-- AppX packages Atlas removes, still registered for any account (2 patterns) --')
        $start | Should -BeGreaterThan 0
        $lines[($start + 1)..($lines.Count - 1)] | Should -Be @(
            'Registered: MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
            '  status=Ok; bundle=False; partially staged=False; non-removable=False; signature=Store'
            '  User registration: S-1-5-21-1000-1000-1000-1000 [S-1-5-21-1000-1000-1000-1000]: Installed'
            'Provisioned: Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe (Atlas only warns when this one stays)'
        )
        Should -Invoke Get-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $AllUsers -and "$PackageTypeFilter" -match 'Bundle' -and "$PackageTypeFilter" -match 'Main'
        }
        # Only what Atlas must remove counts as left behind.
        $script:Summary | Should -Be @('AppX packages Atlas removes: 1 still registered and 0 still provisioned; section 7 lists each with its accounts.')
    }

    It 'leaves out a family whose option wasn''t chosen' {
        Set-Content -LiteralPath (Join-Path $script:atlasState 'state.json') -Value '{ "options": [ "remove-snipping-tool" ] }'

        $lines = @(& $script:AppsCollector)

        $lines | Should -Contain '-- AppX packages Atlas removes, still registered for any account (1 patterns) --'
        $lines | Should -Contain "Not checked, as their option wasn't chosen in state.json: Microsoft.MicrosoftEdge_8wekyb3d8bbwe (uninstall-edge)"
        @($lines | Where-Object { $_ -like 'Provisioned: *' }) | Should -HaveCount 0
    }

    It 'takes the options of an unfinished install over the last one''s' {
        New-Item -ItemType Directory -Path (Join-Path $script:atlasState 'Install') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:atlasState 'Install\active.json') -Value '{ "options": [] }'

        $lines = @(& $script:AppsCollector)

        $lines | Should -Contain "Not checked, as their option wasn't chosen in active.json: Microsoft.MicrosoftEdge_8wekyb3d8bbwe (uninstall-edge)"
    }

    It 'falls back to this account''s packages and the registry''s accounts when the all-users query needs elevation' {
        Mock Get-AppxPackage { throw 'Access is denied.' } -ParameterFilter { $AllUsers }
        Mock Get-AppxPackage { @($script:RegisteredPackages[0]) } -ParameterFilter { -not $AllUsers -and $PackageTypeFilter }
        Mock Get-AppxProvisionedPackage { throw 'The requested operation requires elevation.' }
        Mock Get-AppxAllUserStorePackage {
            [pscustomobject]@{
                Package = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
                Places  = @('listed for S-1-5-21-1000-1000-1000-1000', 'removal pending for S-1-5-21-1000-1000-1000-1003 (EndOfLife)')
                Present = $true
            }
            [pscustomobject]@{
                Package = 'MSTeams_1.0.0.1_x64__8wekyb3d8bbwe'
                Places  = @('listed for S-1-5-21-1000-1000-1000-1000 (stale: its files are gone)')
                Present = $false
            }
        }

        $lines = @(& $script:AppsCollector)

        @($lines | Where-Object { $_ -like 'All-users AppX query failed (needs elevation)*Access is denied.' }) | Should -HaveCount 1
        $lines | Should -Contain 'Registered: MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
        @($lines | Where-Object { $_ -like '  User registration:*' }) | Should -HaveCount 0
        $start = [array]::IndexOf($lines, "-- The same packages in the AppX store's registry, for every account (no install states without elevation) --")
        $start | Should -BeGreaterThan 0
        $lines[$start + 1] | Should -Be 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe: listed for S-1-5-21-1000-1000-1000-1000; removal pending for S-1-5-21-1000-1000-1000-1003 (EndOfLife)'
        $lines[$start + 2] | Should -Be 'MSTeams_1.0.0.1_x64__8wekyb3d8bbwe: listed for S-1-5-21-1000-1000-1000-1000 (stale: its files are gone)'
        Should -Invoke Get-AppxAllUserStorePackage -Times 1 -Exactly -ParameterFilter { @($Pattern) -join ',' -eq 'MSTeams*,Microsoft.MicrosoftEdge_8wekyb3d8bbwe' }
        # One summary line, from the fuller of the two lists, without the stale entry.
        $script:Summary | Should -Be @("AppX packages Atlas removes: 1 still listed, with their files, in the AppX store's registry; section 7 lists the accounts each is listed for.")
    }

    It 'says so when Atlas has no removal list on this machine' {
        $script:atlasModules = Join-Path $TestDrive 'Missing'

        $lines = @(& $script:AppsCollector)

        $lines[-1] | Should -Be "-- AppX packages Atlas removes: no removal list under '$script:atlasModules' --"
        Should -Invoke Get-AppxPackage -Times 0 -Exactly -ParameterFilter { $AllUsers }
    }
}

Describe 'Install report AppX removal list' {
    It 'reads every definition the installed Atlas.Appx module removes, with its option and IgnoreErrors' {
        Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module -Name (Join-Path $script:AtlasTestModulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force
        try {
            # Phone Link counts as IgnoreErrors: the AppX phase only warns when it stays.
            $expected = @(Get-AtlasAppxRemovalDefinition | ForEach-Object { "$($_.Name)|$($_.Option)|$([bool]$_.IgnoreErrors)" }) +
                @('Microsoft.YourPhone*||True')
        }
        finally {
            Remove-Module -Name Atlas.Appx, Atlas.Core -Force -ErrorAction SilentlyContinue
        }

        $actual = @(Get-AppxRemovalPattern -ModulesPath (Split-Path -Parent $script:AtlasTestScriptsRoot) |
                ForEach-Object { "$($_.Pattern)|$($_.Option)|$($_.IgnoreErrors)" })

        $actual | Should -Be $expected
    }
}

Describe 'Install report AppX store registry' {
    BeforeEach {
        $script:testHive = [Microsoft.Win32.Registry]::CurrentUser
        $script:testStore = 'Software\AtlasInstallReportTest\AppxAllUserStore'
        Remove-Item -Path 'HKCU:\Software\AtlasInstallReportTest' -Recurse -Force -ErrorAction SilentlyContinue
    }
    AfterAll {
        Remove-Item -Path 'HKCU:\Software\AtlasInstallReportTest' -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'lists the accounts, pending removals, staging and provisioning of each matching package' {
        $teams = 'MSTeams_26260.1717.5229.7049_x64__8wekyb3d8bbwe'
        $manifest = Join-Path $TestDrive 'AppxManifest.xml'
        Set-Content -LiteralPath $manifest -Value '<Package />'
        $gone = Join-Path $TestDrive 'Gone\AppxManifest.xml'
        foreach ($entry in @(
                @{ Key = "S-1-5-21-1000-1000-1000-1000\$teams"; Path = $manifest }
                @{ Key = 'S-1-5-21-1000-1000-1000-1000\MSTeams_1.0.0.1_x64__8wekyb3d8bbwe'; Path = $gone }
                @{ Key = 'S-1-5-21-1000-1000-1000-1001\Contoso.Kept_1.0_x64__abc'; Path = $manifest }
                @{ Key = "EndOfLife\S-1-5-21-1000-1000-1000-1001\$teams"; Path = $manifest }
                @{ Key = "Deleted\EndOfLife\S-1-5-21-1000-1000-1000-1003\$teams"; Path = $null }
                @{ Key = 'Staged\Microsoft.Windows.DevHome_8wekyb3d8bbwe'; Path = $null }
                @{ Key = 'Applications\Clipchamp.Clipchamp_4.0.10000.0_neutral_~_yxz26nhyzhsrt'; Path = $manifest }
                # Atlas's own markers, not packages anyone has.
                @{ Key = 'Deprovisioned\MSTeams_8wekyb3d8bbwe'; Path = $null }
            )) {
            $item = New-Item -Path "HKCU:\$script:testStore\$($entry.Key)" -Force
            if ($entry.Path) { New-ItemProperty -LiteralPath $item.PSPath -Name Path -Value $entry.Path | Out-Null }
        }

        $found = @(Get-AppxAllUserStorePackage -Pattern 'MSTeams*', 'Microsoft.Windows.DevHome*', 'Clipchamp.Clipchamp*' `
                -Hive $script:testHive -Store $script:testStore)

        @($found | ForEach-Object { "$($_.Package) [$($_.Present)]: $($_.Places -join '; ')" }) | Should -Be @(
            'MSTeams_1.0.0.1_x64__8wekyb3d8bbwe [False]: listed for S-1-5-21-1000-1000-1000-1000 (stale: its files are gone)'
            "$teams [True]: listed for S-1-5-21-1000-1000-1000-1000; removal pending for S-1-5-21-1000-1000-1000-1001 (EndOfLife); removal pending for S-1-5-21-1000-1000-1000-1003 (Deleted\EndOfLife) (no path recorded)"
            'Microsoft.Windows.DevHome_8wekyb3d8bbwe [False]: staged (no path recorded)'
            'Clipchamp.Clipchamp_4.0.10000.0_neutral_~_yxz26nhyzhsrt [True]: provisioned for new accounts'
        )
    }

    It 'matches an exact family pattern against a full package name' {
        New-Item -Path "HKCU:\$script:testStore\S-1-5-21-1000-1000-1000-1000\Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe" -Force | Out-Null
        New-Item -Path "HKCU:\$script:testStore\S-1-5-21-1000-1000-1000-1000\Microsoft.MicrosoftEdge.Stable_155.0.1.0_neutral__8wekyb3d8bbwe" -Force | Out-Null

        $found = @(Get-AppxAllUserStorePackage -Pattern 'Microsoft.MicrosoftEdge_8wekyb3d8bbwe' -Hive $script:testHive -Store $script:testStore)

        @($found | ForEach-Object { $_.Package }) | Should -Be @('Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe')
    }
}

Describe 'Install report Atlas servicing packages' {
    BeforeEach {
        $script:testHive = [Microsoft.Win32.Registry]::CurrentUser
        $script:testPackages = 'Software\AtlasInstallReportTest\Packages'
        Remove-Item -Path 'HKCU:\Software\AtlasInstallReportTest' -Recurse -Force -ErrorAction SilentlyContinue
    }
    AfterAll {
        Remove-Item -Path 'HKCU:\Software\AtlasInstallReportTest' -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'reads state, install time, account, client and source from the registry, without DISM' {
        $key = "HKCU:\$script:testPackages\Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0"
        New-Item -Path $key -Force | Out-Null
        New-Item -Path "HKCU:\$script:testPackages\Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.1.1.1" -Force | Out-Null
        $fileTime = [DateTime]::new(2026, 10, 28, 16, 12, 0, [DateTimeKind]::Utc).ToFileTimeUtc()
        $high = [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]($fileTime -shr 32)), 0)
        $low = [BitConverter]::ToInt32([BitConverter]::GetBytes([uint32]($fileTime -band 0xFFFFFFFFL)), 0)
        New-ItemProperty -Path $key -Name CurrentState -PropertyType DWord -Value 112 | Out-Null
        New-ItemProperty -Path $key -Name InstallTimeHigh -PropertyType DWord -Value $high | Out-Null
        New-ItemProperty -Path $key -Name InstallTimeLow -PropertyType DWord -Value $low | Out-Null
        New-ItemProperty -Path $key -Name InstallUser -PropertyType String -Value 'S-1-5-18' | Out-Null
        New-ItemProperty -Path $key -Name InstallClient -PropertyType String -Value 'DISM Package Manager Provider' | Out-Null
        New-ItemProperty -Path $key -Name InstallLocation -PropertyType String -Value '\\?\C:\WINDOWS\AtlasModules\Packages\NoDefender.cab' | Out-Null

        $lines = @(Get-AtlasServicingPackageLine -Hive $script:testHive -Packages $script:testPackages)

        $lines | Should -Be @(
            'Z-Atlas-NoDefender-Package~31bf3856ad364e35~amd64~~5.0.0.0 [Installed, 112]'
            '  installed 2026-10-28 16:12:00Z by S-1-5-18 through DISM Package Manager Provider'
            '  from \\?\C:\WINDOWS\AtlasModules\Packages\NoDefender.cab'
        )
    }

    It 'says when no Atlas package is installed' {
        New-Item -Path "HKCU:\$script:testPackages\Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.1.1.1" -Force | Out-Null

        Get-AtlasServicingPackageLine -Hive $script:testHive -Packages $script:testPackages | Should -Be 'none installed'
    }

    It 'never asks DISM, which fails without elevation' {
        @($script:ReportAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Get-WindowsPackage'
                }, $true)) | Should -HaveCount 0
    }
}
