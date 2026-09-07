Describe 'Phone Link cross-device Resume state' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
        Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
        $script:phoneLink = Get-AtlasToggleDefinition -Name PhoneLink `
            -TogglesRoot (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles')
        $script:resumePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
        $script:policyPath = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'

        # The Resume values are declarative HKCU entries of each state; the engine
        # applies them as the user part (see Atlas.Toggles.Tests.ps1).
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

    It 'turns off both the master and OneDrive Resume values when disabled' {
        $master = Get-ResumeEntry -StateName Disable -Path $script:resumePath -Name 'IsResumeAllowed'
        $oneDrive = Get-ResumeEntry -StateName Disable -Path $script:resumePath -Name 'IsOneDriveResumeAllowed'
        $policy = Get-ResumeEntry -StateName Disable -Path $script:policyPath -Name 'Value'

        $master | Should -HaveCount 1
        $master[0].Type | Should -BeExactly 'DWord'
        $master[0].Data | Should -Be 0
        $oneDrive | Should -HaveCount 1
        $oneDrive[0].Type | Should -BeExactly 'DWord'
        $oneDrive[0].Data | Should -Be 0
        $policy | Should -HaveCount 1
        $policy[0].Data | Should -Be 1
    }

    It 'turns on both the master and OneDrive Resume values when enabled' {
        $master = Get-ResumeEntry -StateName Enable -Path $script:resumePath -Name 'IsResumeAllowed'
        $oneDrive = Get-ResumeEntry -StateName Enable -Path $script:resumePath -Name 'IsOneDriveResumeAllowed'
        $policy = Get-ResumeEntry -StateName Enable -Path $script:policyPath -Name 'Value'

        $master | Should -HaveCount 1
        $master[0].Type | Should -BeExactly 'DWord'
        $master[0].Data | Should -Be 1
        $oneDrive | Should -HaveCount 1
        $oneDrive[0].Type | Should -BeExactly 'DWord'
        $oneDrive[0].Data | Should -Be 1
        $policy | Should -HaveCount 1
        $policy[0].Data | Should -Be 0
    }

    It 'keeps the Resume values as per-user work beside the machine service change' {
        foreach ($stateName in @('Disable', 'Enable')) {
            $state = $script:phoneLink.States[$stateName]
            $work = Get-AtlasToggleStateWork -Definition $script:phoneLink -StateEntry $state
            $work.Machine | Should -BeTrue -Because $stateName
            $work.User | Should -BeTrue -Because $stateName
            @($state['Services'] | Where-Object { $_.Name -ceq 'CDPSvc' }) | Should -HaveCount 1 -Because $stateName
        }
        $script:phoneLink.States['Disable']['StateValue'] | Should -Be 0
        $script:phoneLink.States['Enable']['StateValue'] | Should -Be 1
    }
}
