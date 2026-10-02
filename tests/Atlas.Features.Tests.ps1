BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:featuresPhase = Join-Path $script:AtlasTestScriptsRoot 'Install\Phases\Invoke-FeaturesPhase.ps1'
    $tokens = $null
    $errors = $null
    $script:featuresAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:featuresPhase, [ref]$tokens, [ref]$errors
    )
    @($errors).Count | Should -Be 0

    $definition = $script:featuresAst.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Get-AtlasDismExitDisposition'
        }, $true)
    $definition | Should -Not -BeNullOrEmpty
    Set-Item Function:\global:Get-AtlasDismExitDisposition `
        -Value $definition.Body.GetScriptBlock()

    Import-Module (Join-Path $PSHOME 'Modules\Dism\Dism.psd1') -ErrorAction Stop
    foreach ($name in @('Invoke-AtlasDism', 'Remove-AtlasStepsRecorder', 'Enable-AtlasDirectPlay')) {
        $function = $script:featuresAst.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
        }, $true)
        Set-Item "Function:\global:$name" -Value $function.Body.GetScriptBlock()
    }
    function Write-AtlasLog { param($Message, $Level) $null = @($Message, $Level) }
    # The phase reads installed Atlas packages and keeps the repair source; the
    # tests stand in for both, so no test reads servicing state or writes policy.
    . (Join-Path $script:AtlasTestScriptsRoot 'Preparation\WindowsTransition.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force

    function Invoke-FeaturesPhase([bool]$IsUpgrade) {
        $script:PhaseUpgrade = $IsUpgrade
        & {
            function Assert-AtlasPrivilege {}
            function Get-AtlasContext { [pscustomobject]@{ WinDir = $TestDrive; IsUpgrade = $script:PhaseUpgrade } }
            . $script:featuresPhase
        }
    }
}

AfterAll {
    Remove-Item Function:\Get-AtlasDismExitDisposition -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-AtlasDism,Function:\Remove-AtlasStepsRecorder -ErrorAction SilentlyContinue
    Remove-Item Function:\Enable-AtlasDirectPlay -ErrorAction SilentlyContinue
}

Describe 'DirectPlay feature enablement' {
    BeforeEach {
        Mock Write-AtlasLog {}
        Mock Invoke-AtlasDism {}
    }

    It 'does not service an already enabled feature' {
        Mock Dism\Get-WindowsOptionalFeature { [pscustomobject]@{ State = 'Enabled' } }
        Enable-AtlasDirectPlay
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
    }

    It 'enables a disabled feature with its dependencies' {
        Mock Dism\Get-WindowsOptionalFeature { [pscustomobject]@{ State = 'Disabled' } }
        Enable-AtlasDirectPlay
        Should -Invoke Invoke-AtlasDism -Times 1 -Exactly -ParameterFilter {
            $Arguments -contains '/Enable-Feature' -and $Arguments -contains '/FeatureName:DirectPlay' -and $Arguments -contains '/All'
        }
    }
}

Describe 'Steps Recorder capability removal' {
    BeforeEach {
        Mock Write-AtlasLog {}
        Mock Invoke-AtlasDism {}
    }

    It 'skips a capability that is no longer in the Windows catalog' {
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'Other.Capability~~~~0.0.1.0'; State = 'Installed' } }
        Remove-AtlasStepsRecorder
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter { $Message -like '*not listed*skipping*' }
    }

    It 'skips Steps Recorder when it is already uninstalled' {
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.1.0'; State = 'NotPresent' } }
        Remove-AtlasStepsRecorder
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
    }

    It 'removes the installed capability using its discovered identity' {
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.2.0'; State = 'Installed' } }
        Remove-AtlasStepsRecorder
        Should -Invoke Invoke-AtlasDism -Times 1 -Exactly -ParameterFilter {
            $Arguments -contains '/Remove-Capability' -and $Arguments -contains '/CapabilityName:App.StepsRecorder~~~~0.0.2.0' -and $Arguments -contains '/NoRestart'
        }
    }

    It 'does not mistake a failed capability query for absence' {
        Mock Dism\Get-WindowsCapability { Write-Error 'servicing query failed' }
        { Remove-AtlasStepsRecorder } | Should -Throw '*servicing query failed*'
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
    }

    It 'rejects pending or unknown servicing states' -ForEach @('InstallPending', 'UninstallPending', 'Unknown') {
        $script:capabilityState = $_
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.1.0'; State = $script:capabilityState } }
        { Remove-AtlasStepsRecorder } | Should -Throw '*unexpected state*'
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
    }
}

Describe 'Features DISM outcomes' {
    It 'accepts success and reboot-required success' {
        Get-AtlasDismExitDisposition -ExitCode 0 | Should -BeExactly 'Success'
        Get-AtlasDismExitDisposition -ExitCode 3010 | Should -BeExactly 'Success'
    }

    It 'defers only explicitly reviewed failures' {
        Get-AtlasDismExitDisposition -ExitCode -2146498554 `
            -DeferredExitCode @(-2146498554) | Should -BeExactly 'Deferred'
        Get-AtlasDismExitDisposition -ExitCode 5 `
            -DeferredExitCode @(-2146498554) | Should -BeExactly 'Failure'
        # 87 is what Windows returns for a capability name it no longer lists.
        Get-AtlasDismExitDisposition -ExitCode 87 | Should -BeExactly 'Failure'
    }

    It 'defers pending operations only for component-store cleanup' {
        Mock Dism\Get-WindowsOptionalFeature { [pscustomobject]@{ State = 'Disabled' } }
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.1.0'; State = 'Installed' } }
        Mock Invoke-AtlasDism {}
        Mock Get-AtlasInstalledAtlasPackage {}
        Mock Update-AtlasCbsRepairSource { 'unchanged' }

        # Run the real phase. The mock outranks the phase's own Invoke-AtlasDism, and
        # WinDir points at TestDrive, so dism.exe can never run.
        Invoke-FeaturesPhase -IsUpgrade $false

        Should -Invoke Invoke-AtlasDism -Times 3 -Exactly
        Should -Invoke Invoke-AtlasDism -Times 1 -Exactly -ParameterFilter {
            $Description -ceq 'Cleaning the component store' -and "$DeferredExitCode" -ceq '-2146498554'
        }
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly -ParameterFilter {
            $Description -cne 'Cleaning the component store' -and $null -ne $DeferredExitCode
        }
    }
}

Describe 'Component store cleanup with the Atlas packages' {
    BeforeEach {
        Mock Dism\Get-WindowsOptionalFeature { [pscustomobject]@{ State = 'Enabled' } }
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.1.0'; State = 'NotPresent' } }
        Mock Invoke-AtlasDism {}
        Mock Write-AtlasLog {}
        Mock Update-AtlasCbsRepairSource { 'recreated' }
    }

    It 'cleans the store on a fresh install, before any Atlas package is installed' {
        Mock Get-AtlasInstalledAtlasPackage {}
        Invoke-FeaturesPhase -IsUpgrade $false
        Should -Invoke Invoke-AtlasDism -Times 1 -Exactly -ParameterFilter { $Arguments -contains '/StartComponentCleanup' }
    }

    It 'never cleans it once an Atlas package is installed, or on an update, and says why' -TestCases @(
        @{ Case = 'an update'; Upgrade = $true; Packages = @() }
        @{ Case = 'an installed NoTelemetry package'; Upgrade = $false; Packages = @('Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0') }
    ) {
        param($Case, $Upgrade, $Packages)
        $script:InstalledPackages = $Packages
        Mock Get-AtlasInstalledAtlasPackage { $script:InstalledPackages }
        Invoke-FeaturesPhase -IsUpgrade $Upgrade
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly -ParameterFilter { $Arguments -contains '/StartComponentCleanup' } -Because $Case
        Should -Invoke Write-AtlasLog -Times 1 -Exactly -ParameterFilter { $Message -like 'Skipped cleaning the component store: *' }
        Should -Invoke Update-AtlasCbsRepairSource -Times 1 -Exactly
    }
}

Describe 'The Atlas packages'' repair source' {
    It 'is recreated while the packages are installed' {
        InModuleScope Atlas.Software {
            Mock New-AtlasCbsRepairSource { $true }
            Mock Remove-AtlasCbsRepairSourcePolicy { throw 'must not remove a source that is recreated' }
            Update-AtlasCbsRepairSource -AtlasPackages @('Z-Atlas-NoTelemetry-Package~31bf3856ad364e35~amd64~~5.0.0.0') | Should -BeExactly 'recreated'
        }
    }

    It 'stops naming a folder that is gone, and leaves any other source alone' {
        InModuleScope Atlas.Software {
            Mock New-AtlasCbsRepairSource { $false }
            Mock Remove-AtlasCbsRepairSourcePolicy {}
            Mock Test-Path { $false } -ParameterFilter { $LiteralPath -like '*AtlasModules\Packages\WinSxS' }
            Mock Get-AtlasCbsRepairSourcePolicy { '%SystemRoot%\AtlasModules\Packages\WinSxS' }
            Update-AtlasCbsRepairSource -AtlasPackages @() | Should -BeExactly 'removed'
            Should -Invoke Remove-AtlasCbsRepairSourcePolicy -Times 1 -Exactly
            # As Windows reads it back, with %SystemRoot% expanded.
            Mock Get-AtlasCbsRepairSourcePolicy { "$env:SystemRoot\AtlasModules\Packages\WinSxS" }
            Update-AtlasCbsRepairSource -AtlasPackages @() | Should -BeExactly 'removed'
            Should -Invoke Remove-AtlasCbsRepairSourcePolicy -Times 2 -Exactly
            Mock Get-AtlasCbsRepairSourcePolicy { 'D:\Sources\WinSxS' }
            Update-AtlasCbsRepairSource -AtlasPackages @() | Should -BeExactly 'unchanged'
            Mock Get-AtlasCbsRepairSourcePolicy { $null }
            Update-AtlasCbsRepairSource -AtlasPackages @() | Should -BeExactly 'unchanged'
            Should -Invoke Remove-AtlasCbsRepairSourcePolicy -Times 2 -Exactly
        }
    }
}
