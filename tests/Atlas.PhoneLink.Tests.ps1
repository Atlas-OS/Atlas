Describe 'Phone Link cross-device Resume state' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:phoneLink = Get-AtlasToggleDefinition -Name PhoneLink `
            -TogglesRoot (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles')
        $script:resumePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
        $script:policyPath = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'

        function Get-ResumeEntry {
            param(
                [Parameter(Mandatory = $true)][string]$StateName,
                [Parameter(Mandatory = $true)][string]$Path,
                [Parameter(Mandatory = $true)][string]$Name
            )

            # The comma keeps a single matching hashtable wrapped as an array.
            return , @($script:phoneLink.States[$StateName]['Registry'] | Where-Object {
                    $_.Path -ceq $Path -and $_.Name -ceq $Name
                })
        }
    }

    It 'sets both the master and OneDrive Resume values when <StateName>d' -ForEach @(
        @{ StateName = 'Disable'; Allowed = 0; DisablePolicy = 1 }
        @{ StateName = 'Enable'; Allowed = 1; DisablePolicy = 0 }
    ) {
        $master = Get-ResumeEntry -StateName $StateName -Path $script:resumePath -Name 'IsResumeAllowed'
        $oneDrive = Get-ResumeEntry -StateName $StateName -Path $script:resumePath -Name 'IsOneDriveResumeAllowed'
        $policy = Get-ResumeEntry -StateName $StateName -Path $script:policyPath -Name 'Value'

        $master | Should -HaveCount 1
        $master[0].Type | Should -BeExactly 'DWord'
        $master[0].Data | Should -Be $Allowed
        $oneDrive | Should -HaveCount 1
        $oneDrive[0].Type | Should -BeExactly 'DWord'
        $oneDrive[0].Data | Should -Be $Allowed
        $policy | Should -HaveCount 1
        $policy[0].Data | Should -Be $DisablePolicy
    }

    It 'keeps the shared CDP service available with Phone Link enabled or disabled' {
        foreach ($stateName in @('Disable', 'Enable')) {
            $service = @($script:phoneLink.States[$stateName]['Services'] | Where-Object Name -ceq 'CDPSvc')
            $service | Should -HaveCount 1
            $service[0].StartupType | Should -Be 3 -Because 'disabling Phone Link must not disable the shared Night Light service'
        }
        $script:phoneLink.States['Disable']['MachineAction'] | Should -BeExactly 'Disable-AtlasPhoneLinkMachine'
    }
}
