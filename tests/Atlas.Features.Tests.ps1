BeforeAll {
    $script:featuresPhase = Join-Path $PSScriptRoot `
        '..\playbook\Executables\AtlasModules\Scripts\Phases\Invoke-FeaturesPhase.ps1'
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
}

AfterAll {
    Remove-Item Function:\Get-AtlasDismExitDisposition -ErrorAction SilentlyContinue
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
