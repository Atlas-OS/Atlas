BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:featuresPhase = Join-Path $PSScriptRoot `
        '..\playbook\Executables\AtlasModules\Scripts\Install\Phases\Invoke-FeaturesPhase.ps1'
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

    It 'propagates a failed feature query' {
        Mock Dism\Get-WindowsOptionalFeature { throw 'feature query failed' }
        { Enable-AtlasDirectPlay } | Should -Throw '*feature query failed*'
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
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
        Mock Dism\Get-WindowsCapability { throw 'servicing query failed' }
        { Remove-AtlasStepsRecorder } | Should -Throw '*servicing query failed*'
        Should -Invoke Invoke-AtlasDism -Times 0 -Exactly
    }

    It 'does not hide a removal failure, including error 87' {
        Mock Dism\Get-WindowsCapability { [pscustomobject]@{ Name = 'App.StepsRecorder~~~~0.0.1.0'; State = 'Installed' } }
        Mock Invoke-AtlasDism { throw 'DISM failed with exit code 87' }
        { Remove-AtlasStepsRecorder } | Should -Throw '*exit code 87*'
        Get-AtlasDismExitDisposition -ExitCode 87 | Should -BeExactly 'Failure'
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
    }

    It 'defers pending operations only for component-store cleanup' {
        $cleanup = @($script:featuresAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Invoke-AtlasDism' -and
                    $node.Extent.Text -match 'Cleaning the component store'
                }, $true))
        $cleanup.Count | Should -Be 1
        $cleanup[0].Extent.Text | Should -Match '-DeferredExitCode\s+@\(-2146498554\)'

        $otherCalls = @($script:featuresAst.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -eq 'Invoke-AtlasDism' -and
                    $node.Extent.Text -notmatch 'Cleaning the component store'
                }, $true))
        @($otherCalls | Where-Object {
                $_.Extent.Text -match '-DeferredExitCode'
            }).Count | Should -Be 0
    }
}
