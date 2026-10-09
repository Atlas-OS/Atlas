BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force
    $script:searchRoot = 'HKCU:\Software\AtlasRewriteTest\SearchPrivacy'
    $script:searchSettings = "$script:searchRoot\SearchSettings"
    $script:searchValues = "$script:searchRoot\Values"
    $script:currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $script:refusal = InModuleScope Atlas.Registry {
        New-AtlasRegistryValueRefusedRecord -ProviderPath 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SearchSettings' `
            -Name IsAADCloudSearchEnabled -Cause ([UnauthorizedAccessException]::new('Access denied'))
    }
}

Describe 'Search privacy on Windows that refuses per-user preferences' {
    BeforeEach {
        New-Item -Path $script:searchValues -Force | Out-Null
        InModuleScope Atlas.Registry { $script:AtlasRegistryIdentityContext = $null }
        Initialize-AtlasRegistryIdentityContext -CurrentToken -ExpectedUserSid $script:currentSid | Out-Null
        Mock Write-AtlasLog -ModuleName Atlas.Registry {}
        Mock Invoke-AtlasRegistryTargetOperation -ModuleName Atlas.Registry {
            throw $script:refusal
        } -ParameterFilter { $Path -eq 'HKCU:\Software\AtlasRewriteTest\SearchPrivacy\SearchSettings' }
    }
    AfterEach {
        Remove-Item -LiteralPath $script:searchRoot -Recurse -Force
    }

    It 'finishes <Route> while keeping cloud search controlled by machine policy' -ForEach @(
        @{ Route = 'Privacy tweak' }
        @{ Route = 'Disable Web Search' }
        @{ Route = 'Enable Web Search' }
    ) {
        if ($Route -eq 'Privacy tweak') {
            $definition = Import-PowerShellDataFile (Join-Path $script:AtlasTestScriptsRoot 'Tweaks\privacy\search-settings.psd1')
            $entries = $definition.Registry
            $expectedMode = 1
        } else {
            $definition = Import-PowerShellDataFile (Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles\General\WebSearch.psd1')
            $stateName = if ($Route -eq 'Enable Web Search') { 'Enable' } else { 'Disable' }
            $entries = @($definition.States | Where-Object Name -eq $stateName)[0].Registry
            $expectedMode = if ($stateName -eq 'Enable') { 2 } else { 1 }
        }
        foreach ($entry in $entries) {
            $entry.Path = if ($entry.Path -like '*\SearchSettings') { $script:searchSettings } else { $script:searchValues }
        }
        Set-ItemProperty -LiteralPath $script:searchValues -Name AllowCloudSearch -Type DWord -Value 1
        { Invoke-AtlasRegistryEntries -Entries $entries -IsArm64 $false } | Should -Not -Throw
        $values = Get-Item -LiteralPath $script:searchValues
        $values.GetValue('SearchboxTaskbarMode') | Should -Be $expectedMode
        if ($Route -eq 'Enable Web Search') {
            $values.GetValue('AllowCloudSearch', $null) | Should -BeNullOrEmpty
        } else {
            $values.GetValue('AllowCloudSearch') | Should -Be 0
        }
        $refusedCount = @($entries | Where-Object Path -eq $script:searchSettings).Count
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Registry -Times $refusedCount -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -match 'Continuing without'
        }
    }

    It 'does not hide a failure to apply the required cloud-search policy' {
        $definition = Import-PowerShellDataFile (Join-Path $script:AtlasTestScriptsRoot 'Tweaks\privacy\search-settings.psd1')
        $entries = @($definition.Registry | Where-Object Name -eq AllowCloudSearch)
        $entries[0].Path = $script:searchValues
        Mock Invoke-AtlasRegistryTargetOperation -ModuleName Atlas.Registry {
            throw $script:refusal
        } -ParameterFilter { $Path -eq 'HKCU:\Software\AtlasRewriteTest\SearchPrivacy\Values' }
        { Invoke-AtlasRegistryEntries -Entries $entries -IsArm64 $false } | Should -Throw '*AllowCloudSearch*'
    }

    It 'does not hide other registry failures in optional search preferences' {
        $definition = Import-PowerShellDataFile (Join-Path $script:AtlasTestScriptsRoot 'Tweaks\privacy\search-settings.psd1')
        $entries = @($definition.Registry | Where-Object Name -eq IsAADCloudSearchEnabled)
        $entries[0].Path = $script:searchSettings
        Mock Invoke-AtlasRegistryTargetOperation -ModuleName Atlas.Registry {
            throw 'Unexpected registry failure'
        } -ParameterFilter { $Path -eq 'HKCU:\Software\AtlasRewriteTest\SearchPrivacy\SearchSettings' }
        { Invoke-AtlasRegistryEntries -Entries $entries -IsArm64 $false } | Should -Throw '*Unexpected registry failure*'
    }
}
