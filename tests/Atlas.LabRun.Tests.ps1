BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $labScript = Join-Path $script:AtlasTestRepoRoot 'tools\lab\Invoke-AtlasLabRun.ps1'
    $labAst = [Management.Automation.Language.Parser]::ParseFile($labScript, [ref]$null, [ref]$null)
    foreach ($name in 'Get-FrontDoorCommand', 'Get-LabTaskRunner') {
        $function = $labAst.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
            }, $true)
        . ([scriptblock]::Create($function.Extent.Text))
    }
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'

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

    # Windows PowerShell turns redirected native stderr into error records.
    function Invoke-PowerShell51 {
        param([Parameter(Mandatory = $true)][string[]]$Arguments)
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass @Arguments 2>&1 |
                ForEach-Object { "$_" }
        }
        finally {
            $ErrorActionPreference = $savedPreference
        }
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
    }
}

Describe 'Lab front door command' {
    BeforeAll {
        function Invoke-FrontDoorCommand {
            param([string[]]$Option)
            Invoke-PowerShell51 -Arguments @('-Command', (Get-FrontDoorCommand -ScriptPath $script:Stub -Option $Option))
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

Describe 'Lab task runner' {
    BeforeEach {
        # A folder name with an apostrophe and a space, like any path the runner may get.
        $script:runnerRoot = Join-Path $TestDrive "Atlas Lab's $([guid]::NewGuid().ToString('N'))"
        New-Item -Path $script:runnerRoot -ItemType Directory -Force | Out-Null
        $script:paths = @{
            Started = Join-Path $script:runnerRoot 'session.json'
            Log     = Join-Path $script:runnerRoot 'front-door.log'
            Result  = Join-Path $script:runnerRoot 'result.json'
        }
    }

    BeforeAll {
        function Invoke-LabTaskRunner {
            param([string[]]$Option)
            $runner = Get-LabTaskRunner -Command (Get-FrontDoorCommand -ScriptPath $script:Stub -Option $Option) `
                -StartedPath $script:paths.Started -LogPath $script:paths.Log -ResultPath $script:paths.Result
            $runnerPath = Join-Path $script:runnerRoot 'Invoke-FrontDoorTask.ps1'
            [IO.File]::WriteAllText($runnerPath, $runner, (New-Object Text.UTF8Encoding($true)))
            Invoke-PowerShell51 -Arguments @('-File', $runnerPath)
        }
    }

    It 'records its session, the front door''s output and its exit code' {
        $run = Invoke-LabTaskRunner -Option 'defender-enable', 'mitigations-default'

        $run.ExitCode | Should -Be 5 -Because ($run.Output -join "`n")
        $started = Get-Content -LiteralPath $script:paths.Started -Raw | ConvertFrom-Json
        $started.user | Should -BeExactly ([Security.Principal.WindowsIdentity]::GetCurrent().Name)
        $started.sessionId | Should -Be ([Diagnostics.Process]::GetCurrentProcess().SessionId)
        @(Get-Content -LiteralPath $script:paths.Log) | Should -Contain 'bound defender-enable|mitigations-default unattended=True'
        $result = Get-Content -LiteralPath $script:paths.Result -Raw | ConvertFrom-Json
        $result.exitCode | Should -Be 5
        "$($script:paths.Result).tmp" | Should -Not -Exist
    }

    It 'records exit code 1 and the error for a front door that throws' {
        $run = Invoke-LabTaskRunner -Option 'throws'

        $run.ExitCode | Should -Be 1 -Because ($run.Output -join "`n")
        @(Get-Content -LiteralPath $script:paths.Log) | Should -Contain 'front door threw'
        (Get-Content -LiteralPath $script:paths.Result -Raw | ConvertFrom-Json).exitCode | Should -Be 1
    }

    It 'still writes a result when it can''t start the front door' {
        # A log path in a folder that doesn't exist makes the runner fail before the front door.
        $script:paths.Log = Join-Path $script:runnerRoot 'missing\front-door.log'
        $run = Invoke-LabTaskRunner -Option 'defender-enable'

        $run.ExitCode | Should -Be 1 -Because ($run.Output -join "`n")
        $result = Get-Content -LiteralPath $script:paths.Result -Raw | ConvertFrom-Json
        $result.exitCode | Should -Be 1
        $result.detail | Should -Not -BeNullOrEmpty
    }
}
