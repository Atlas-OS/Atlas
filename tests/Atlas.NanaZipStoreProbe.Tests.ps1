BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '..\tools\dev\NanaZipStoreProbe.psm1') -Force
}
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\tools\dev\NanaZipStoreProbe.psm1') -Force
}
Describe 'NanaZip Store probe operation' {
    InModuleScope NanaZipStoreProbe {
        BeforeAll {
            # Stand-ins make these orchestration tests independent of installed WinGet.
            function Find-WinGetPackage { param($Id, $Source, $MatchOption) $null = @($Id, $Source, $MatchOption) }
            function Install-WinGetPackage { param($PSCatalogPackage, $Scope, $Mode) $null = @($PSCatalogPackage, $Scope, $Mode) }
        }
        BeforeEach {
            Mock Get-NanaZipProbeContext { @{ IsSystem = $false; Elevated = $true } }
            Mock Test-ModuleManifest { @{ Name = 'Microsoft.WinGet.Client'; Version = [version]'1.29.280' } }
            Mock Import-Module {}
            Mock Get-NanaZipProvisioned { @() }
            Mock Find-WinGetPackage { [pscustomobject]@{ Id = '9N8G7TSCL18R'; Name = 'NanaZip'; Source = 'msstore'; Version = 'Unknown' } }
            Mock Install-WinGetPackage { throw 'unexpected install' }
            $script:reportFile = Join-Path $TestDrive 'report.json'
        }
        It 'only queries the exact Store product by default' {
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile
            $result.Phase | Should -Be LookupSucceeded
            Should -Invoke Find-WinGetPackage -Times 1 -Exactly -ParameterFilter { $Id -ceq '9N8G7TSCL18R' -and $Source -eq 'msstore' -and $MatchOption -eq 'Equals' }
            Should -Invoke Install-WinGetPackage -Times 0 -Exactly
        }
        It 'permits fallback after failed lookup without invoking installation' {
            Mock Find-WinGetPackage { throw 'Store unavailable' }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be DownloadFallbackAllowed
            $result.Error.Message | Should -Be 'Store unavailable'
            Should -Invoke Install-WinGetPackage -Times 0 -Exactly
        }
        It 'reports the unsupported SYSTEM Windows PowerShell host before COM activation' {
            if ($PSVersionTable.PSEdition -ne 'Desktop') { Set-ItResult -Skipped -Because 'Windows PowerShell specific restriction'; return }
            Mock Get-NanaZipProbeContext { @{ IsSystem = $true; Elevated = $true } }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be DownloadFallbackAllowed
            $result.Error.Message | Should -BeLike '*does not support SYSTEM in Windows PowerShell 5.1*'
            Should -Invoke Find-WinGetPackage -Times 0 -Exactly
            Should -Invoke Install-WinGetPackage -Times 0 -Exactly
        }
        It 'refuses an ambiguous or substituted Store product' {
            Mock Find-WinGetPackage { [pscustomobject]@{ Id = 'different-product'; Source = 'msstore' } }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.InstallStarted | Should -BeFalse
            Should -Invoke Install-WinGetPackage -Times 0 -Exactly
        }
        It 'checkpoints before COM installation and never recommends fallback after an exception' {
            Mock Install-WinGetPackage {
                $checkpoint = Get-Content $script:reportFile -Raw | ConvertFrom-Json
                $checkpoint.InstallStarted | Should -BeTrue
                $checkpoint.Decision | Should -Be InspectBeforeRetry
                throw 'COM disconnected'
            }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be InspectBeforeRetry
            Should -Invoke Install-WinGetPackage -Times 1 -Exactly -ParameterFilter { $Scope -eq 'System' -and $Mode -eq 'Silent' }
        }
        It 'does not call a user-only installation successful' {
            Mock Install-WinGetPackage { [pscustomobject]@{ Status = 'Ok'; InstallerErrorCode = 0; RebootRequired = $false; CorrelationData = 'test'; ExtendedErrorCode = $null } }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be InspectBeforeRetry
        }
        It 'succeeds only after machine provisioning is observed' {
            $script:reads = 0
            Mock Get-NanaZipProvisioned { $script:reads++; if ($script:reads -gt 1) { @{ DisplayName = '40174MouriNaruto.NanaZip'; Version = '7.0.1843.0' } } }
            Mock Install-WinGetPackage { [pscustomobject]@{ Status = 'Ok'; InstallerErrorCode = 0; RebootRequired = $false; CorrelationData = 'test'; ExtendedErrorCode = $null } }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be Installed
            $result.Phase | Should -Be Complete
            $result.Result.ExtendedHResult | Should -BeNullOrEmpty
        }
        It 'does not reinstall a provisioned package' {
            Mock Get-NanaZipProvisioned { @{ DisplayName = '40174MouriNaruto.NanaZip' } }
            $result = Invoke-NanaZipStoreProbe -ClientManifest 'fixture.psd1' -ReportPath $script:reportFile -Install
            $result.Decision | Should -Be AlreadyProvisioned
            Should -Invoke Install-WinGetPackage -Times 0 -Exactly
        }
    }
}
Describe 'NanaZip Store fallback boundary' {
    It 'allows a download fallback when COM fails before installation' {
        Get-NanaZipStoreDecision -InstallStarted $false -Status Failed -Provisioned $false | Should -Be DownloadFallbackAllowed
    }
    It 'requires both Store success and provisioning proof' {
        Get-NanaZipStoreDecision -InstallStarted $true -Status Ok -Provisioned $true | Should -Be Installed
        Get-NanaZipStoreDecision -InstallStarted $true -Status Ok -Provisioned $false | Should -Be InspectBeforeRetry
    }
    It 'never recommends another installer after a failed or cancelled mutation' -ForEach @('Failed', 'Cancelled', 'TimedOut', 'Unknown') {
        Get-NanaZipStoreDecision -InstallStarted $true -Status $_ -Provisioned $false | Should -Be InspectBeforeRetry
        Get-NanaZipStoreDecision -InstallStarted $true -Status $_ -Provisioned $true | Should -Be InspectBeforeRetry
    }
}
