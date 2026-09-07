BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Download\Atlas.Download.psd1') -Force
    $root = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    . (Join-Path $root 'Advanced\MicrosoftStore.ps1')
    . (Join-Path $root 'General\Widgets.ps1')
    . (Join-Path $root 'General\SystemRestore.ps1')
}

Describe 'User app restoration outcomes' {
    BeforeEach {
        $script:healthy = $false
        Mock Get-AppxPackage { if ($script:healthy) { [pscustomobject]@{ Status = 'Ok' } } }
        Mock Add-AppxPackage { $script:healthy = $true }
        Mock Import-AtlasModule {}
        Mock Get-AtlasTrustedWingetPath { 'TestDrive:\winget.exe' }
        Mock Assert-AtlasTrustedWingetSource {}
        Mock Invoke-AtlasToggleNativeCommand { $script:healthy = $true }
        Mock Start-Process {}
    }

    It 'registers a staged Store family for the current user' {
        Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $RegisterByFamilyName -and $MainPackage -eq 'Microsoft.WindowsStore_8wekyb3d8bbwe'
        }
        Should -Invoke Get-AppxPackage -Times 2 -Exactly -ParameterFilter { -not $AllUsers }
    }

    It 'does not register Store again when it is already healthy' {
        $script:healthy = $true
        Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Not -Invoke Add-AppxPackage
    }

    It 'downloads the exact Store product when its staged payload is gone' {
        Mock Add-AppxPackage { throw 'payload unavailable' }
        Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true })
        Should -Invoke Assert-AtlasTrustedWingetSource -Times 1 -Exactly -ParameterFilter { $Name -eq 'msstore' }
        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'TestDrive:\winget.exe' -and $ArgumentList -contains '9WZDNCRFJBMP' -and
            $ArgumentList -contains '--exact' -and $ArgumentList -contains 'msstore' -and
            $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
    }

    It 'propagates a failed Store download instead of claiming restoration' {
        Mock Add-AppxPackage { throw 'payload unavailable' }
        Mock Invoke-AtlasToggleNativeCommand { throw 'Store download failed' }
        { Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true }) } | Should -Throw '*Store download failed*'
    }

    It 'rejects a successful download that leaves no healthy Store package' {
        Mock Add-AppxPackage { throw 'payload unavailable' }
        Mock Invoke-AtlasToggleNativeCommand {}
        { Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true }) } | Should -Throw '*healthy*'
    }

    It 'does not download Store through an untrusted source' {
        Mock Add-AppxPackage { throw 'payload unavailable' }
        Mock Assert-AtlasTrustedWingetSource { throw 'untrusted source' }
        { Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true }) } | Should -Throw '*untrusted source*'
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand
    }

    It 'rejects Store registration that leaves no healthy app' {
        Mock Add-AppxPackage {}
        { Register-AtlasMicrosoftStore -Toggle ([pscustomobject]@{ Silent = $true }) } | Should -Throw '*healthy*'
    }

    It 'restores Widgets through the exact trusted Store product before opening settings' {
        Install-AtlasWidgetsUser -Toggle ([pscustomobject]@{ Silent = $false })
        Should -Invoke Assert-AtlasTrustedWingetSource -Times 1 -Exactly -ParameterFilter { $Name -eq 'msstore' }
        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains '9MSSGKG348SP' -and $ArgumentList -contains '--exact' -and $AllowedExitCodes.Count -eq 1 -and $AllowedExitCodes[0] -eq 0
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter { $FilePath -eq 'ms-settings:taskbar' }
    }

    It 'does not open Widgets settings after an ineffective installation' {
        Mock Invoke-AtlasToggleNativeCommand {}
        { Install-AtlasWidgetsUser -Toggle ([pscustomobject]@{ Silent = $false }) } | Should -Throw '*not healthy*'
        Should -Not -Invoke Start-Process
    }

    It 'restores the missing feed provider even when the Widgets board is healthy' {
        Mock Get-AppxPackage {
            if ($Name -eq 'MicrosoftWindows.Client.WebExperience' -or $script:healthy) {
                [pscustomobject]@{ Status = 'Ok' }
            }
        }
        Install-AtlasWidgetsUser -Toggle ([pscustomobject]@{ Silent = $false })
        Should -Invoke Invoke-AtlasToggleNativeCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains '9PC1H9VN18CM' -and $ArgumentList -contains '--exact'
        }
        Should -Invoke Start-Process -Times 1 -Exactly
    }

    It 'does not claim complete restoration when the feed provider remains missing' {
        Mock Get-AppxPackage {
            if ($Name -eq 'MicrosoftWindows.Client.WebExperience') { [pscustomobject]@{ Status = 'Ok' } }
        }
        { Install-AtlasWidgetsUser -Toggle ([pscustomobject]@{ Silent = $false }) } |
            Should -Throw '*Start Experiences App is not healthy*'
        Should -Not -Invoke Start-Process
    }
}

Describe 'System Restore enable outcome' {
    It 'enables Windows volume protection and propagates failure' {
        Mock Enable-ComputerRestore { throw 'protection unavailable' }
        { Enable-AtlasWindowsVolumeProtection -Toggle ([pscustomobject]@{ Silent = $true }) } | Should -Throw '*protection unavailable*'
        Should -Invoke Enable-ComputerRestore -Times 1 -Exactly -ParameterFilter {
            $Drive -eq [IO.Path]::GetPathRoot([Environment]::GetFolderPath('Windows')) -and $ErrorAction -eq 'Stop'
        }
    }
}

Describe 'Explicit enable state boundaries' {
    BeforeAll {
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Privacy\Atlas.Privacy.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
        . (Join-Path $root 'General\Location.ps1')
    }
    BeforeEach {
        Mock Import-AtlasModule {}
        Mock Set-AtlasLocationMachineState {}
        Mock Remove-AtlasRegistryValue {}
        Mock Set-AtlasRegistryValue {}
        Mock Set-AtlasSettingsPageVisibility {}
        Mock Read-AtlasYesNo { $false }
        Mock Start-Process {}
    }
    It 'preserves Find My Device when its separate change is declined' {
        Enable-AtlasLocation -Toggle ([pscustomobject]@{ Silent = $false })
        Should -Not -Invoke Remove-AtlasRegistryValue
        Should -Not -Invoke Set-AtlasRegistryValue
        Should -Not -Invoke Set-AtlasSettingsPageVisibility
        Should -Not -Invoke Start-Process
    }
    It 'unlocks only the two Atlas Find My Device restrictions after acceptance' {
        Mock Read-AtlasYesNo { $true }
        Enable-AtlasLocation -Toggle ([pscustomobject]@{ Silent = $false })
        Should -Invoke Remove-AtlasRegistryValue -Times 2 -Exactly -ParameterFilter {
            $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' -and $Name -in @('AllowFindMyDevice','LocationSyncEnabled')
        }
        Should -Not -Invoke Set-AtlasRegistryValue
    }
    It 'encodes update-notification activation separately from the selected level' {
        $definition = Get-AtlasToggleDefinition -Name UpdateNotifications -TogglesRoot $root
        $entries = @($definition.States.Disable.Registry)
        ($entries | Where-Object Name -eq SetUpdateNotificationLevel).Data | Should -Be 1
        ($entries | Where-Object Name -eq UpdateNotificationLevel).Data | Should -Be 2
        @($definition.States.Enable.Registry | Where-Object { $_.Name -in @('SetUpdateNotificationLevel','UpdateNotificationLevel') -and $_.Operation -eq 'Delete' }).Count | Should -Be 2
    }
}
