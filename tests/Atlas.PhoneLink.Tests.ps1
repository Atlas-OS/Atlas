Describe 'Phone Link cross-device Resume state' {
    BeforeAll {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $script:phoneLinkPath = Join-Path $repoRoot `
            'playbook\Executables\AtlasModules\Toggles\General\PhoneLink.ps1'
    }

    BeforeEach {
        $script:registryWrites = @()

        function Import-Module {
            param(
                [string]$Name,
                [System.Management.Automation.ActionPreference]$ErrorAction
            )
        }

        function Set-AtlasRegistryValue {
            param(
                [string]$Path,
                [string]$Name,
                [string]$Type,
                [object]$Data
            )

            $script:registryWrites += [pscustomobject]@{
                Path = $Path
                Name = $Name
                Type = $Type
                Data = $Data
            }
        }

        $script:definition = & $script:phoneLinkPath
    }

    AfterEach {
        Remove-Item Function:\Import-Module -ErrorAction SilentlyContinue
        Remove-Item Function:\Set-AtlasRegistryValue -ErrorAction SilentlyContinue
    }

    It 'turns off both the master and OneDrive Resume values when disabled' {
        $toggle = [pscustomobject]@{
            ScriptsPath = $TestDrive
            State       = 'Disable'
            Silent      = $true
        }

        & $script:definition.States.Disable.UserAction $toggle

        $resumeWrites = @($script:registryWrites | Where-Object {
                $_.Path -ceq 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
            })
        $resumeWrites.Count | Should -Be 2
        ($resumeWrites | Where-Object Name -CEQ 'IsResumeAllowed').Data |
            Should -Be 0
        ($resumeWrites | Where-Object Name -CEQ 'IsOneDriveResumeAllowed').Data |
            Should -Be 0
        ($script:registryWrites | Where-Object {
                $_.Name -ceq 'Value' -and
                $_.Path -ceq 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
            }).Data | Should -Be 1
    }

    It 'turns on both the master and OneDrive Resume values when enabled' {
        $toggle = [pscustomobject]@{
            ScriptsPath = $TestDrive
            State       = 'Enable'
            Silent      = $true
        }

        & $script:definition.States.Enable.UserAction $toggle

        $resumeWrites = @($script:registryWrites | Where-Object {
                $_.Path -ceq 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
            })
        $resumeWrites.Count | Should -Be 2
        ($resumeWrites | Where-Object Name -CEQ 'IsResumeAllowed').Data |
            Should -Be 1
        ($resumeWrites | Where-Object Name -CEQ 'IsOneDriveResumeAllowed').Data |
            Should -Be 1
        ($script:registryWrites | Where-Object {
                $_.Name -ceq 'Value' -and
                $_.Path -ceq 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
            }).Data | Should -Be 0
    }
}
