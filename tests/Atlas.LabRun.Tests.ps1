BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $labScript = Join-Path $script:AtlasTestRepoRoot 'tools\lab\Invoke-AtlasLabRun.ps1'
    $labAst = [Management.Automation.Language.Parser]::ParseFile($labScript, [ref]$null, [ref]$null)
    $function = $labAst.Find({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-FrontDoorCommand'
        }, $true)
    . ([scriptblock]::Create($function.Extent.Text))
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'
}

Describe 'Lab front door command' {
    BeforeAll {
        # A stand-in with the real front door's parameters that reports what bound.
        $frontDoor = Join-Path $script:AtlasTestScriptsRoot 'Entry\Install-Atlas.ps1'
        $frontDoorAst = [Management.Automation.Language.Parser]::ParseFile($frontDoor, [ref]$null, [ref]$null)
        $script:Stub = Join-Path $TestDrive "Install O'Atlas.ps1"
        [IO.File]::WriteAllText($script:Stub, $frontDoorAst.ParamBlock.Extent.Text + @'

"bound $($Option -join '|') unattended=$Unattended"
if ($Option -contains 'throws') { throw 'front door threw' }
if ($Option -contains 'returns') { return }
exit 5
'@)

        function Invoke-FrontDoorCommand {
            param([string[]]$Option)
            $command = Get-FrontDoorCommand -ScriptPath $script:Stub -Option $Option
            # Windows PowerShell turns redirected native stderr into error records.
            $savedPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $command 2>&1 |
                    ForEach-Object { "$_" }
            }
            finally {
                $ErrorActionPreference = $savedPreference
            }
            [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
        }
    }

    It 'binds every option as an array and passes on the exit code' {
        $result = Invoke-FrontDoorCommand -Option 'defender-enable', 'mitigations-default'
        $result.ExitCode | Should -Be 5 -Because ($result.Output -join "`n")
        $result.Output | Should -Contain 'bound defender-enable|mitigations-default unattended=True'
    }

    It 'counts a front door that <Case> as exit code 1' -TestCases @(
        @{ Case = 'throws'; Option = 'throws' }
        @{ Case = 'sets no exit code'; Option = 'returns' }
    ) {
        $result = Invoke-FrontDoorCommand -Option $Option
        $result.ExitCode | Should -Be 1 -Because ($result.Output -join "`n")
    }
}
