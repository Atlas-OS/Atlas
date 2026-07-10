BeforeAll {
    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
    $script:FeaturesPhase = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Phases\Invoke-FeaturesPhase.ps1'
    $script:ProcessExplorerCleanup = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Tasks\Stop-ProcessExplorerUpgrade.ps1'
    $script:CustomYaml = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Configuration\custom.yml'

    $tokens = $null
    $parseErrors = $null
    $featuresAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:FeaturesPhase,
        [ref]$tokens,
        [ref]$parseErrors
    )
    $parseErrors | Should -BeNullOrEmpty

    $invokeDismFunction = $featuresAst.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Invoke-AtlasDism'
        }, $true)
    $script:InvokeDismDefinition = [scriptblock]::Create($invokeDismFunction.Extent.Text)

    function New-TestProcessStub {
        param(
            [int]$ExitCode,
            [bool]$Completes = $true
        )

        $stub = [pscustomobject]@{
            ExitCode                = $ExitCode
            Completes               = $Completes
            WaitTimeoutMilliseconds = 0
        }
        $stub | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value {
            param([int]$TimeoutMilliseconds)

            $this.WaitTimeoutMilliseconds = $TimeoutMilliseconds
            return [bool]$this.Completes
        }
        return $stub
    }
}

Describe 'Required DISM operations' {
    It 'accepts Windows success code <ExitCode>' -TestCases @(
        @{ ExitCode = 0 }
        @{ ExitCode = 3010 }
    ) {
        $runner = {
            param(
                [Parameter(Mandatory = $true)][scriptblock]$Definition,
                [Parameter(Mandatory = $true)][string]$NativeCommand,
                [Parameter(Mandatory = $true)][int]$ExpectedExitCode
            )

            function Write-AtlasLog {
                param([string]$Message)

                [void]$Message
            }

            Set-Variable -Name 'dism' -Value $NativeCommand
            . $Definition
            Invoke-AtlasDism -Description 'Test servicing operation' -Arguments @('/d', '/c', "exit $ExpectedExitCode")
        }

        { & $runner $script:InvokeDismDefinition $env:ComSpec $ExitCode } | Should -Not -Throw
    }

    It 'throws when DISM returns a non-success exit code' {
        $runner = {
            param(
                [Parameter(Mandatory = $true)][scriptblock]$Definition,
                [Parameter(Mandatory = $true)][string]$NativeCommand
            )

            function Write-AtlasLog {
                param([string]$Message)

                [void]$Message
            }

            Set-Variable -Name 'dism' -Value $NativeCommand
            . $Definition
            Invoke-AtlasDism -Description 'Test servicing operation' -Arguments @('/d', '/c', 'exit 87')
        }

        { & $runner $script:InvokeDismDefinition $env:ComSpec } |
            Should -Throw -ExpectedMessage '*failed with exit code 87*'
    }
}

Describe 'Process Explorer upgrade cleanup' {
    BeforeEach {
        $UninstallProcessStub = New-TestProcessStub -ExitCode 0
        $TaskkillProcessStub = New-TestProcessStub -ExitCode 128

        Mock Test-Path { $true } -ParameterFilter {
            $LiteralPath -like '*Uninstall Process Explorer.cmd' -and $PathType -eq 'Leaf'
        }
        Mock Start-Process {
            if ($FilePath -like '*Uninstall Process Explorer.cmd') {
                return $UninstallProcessStub
            }
            return $TaskkillProcessStub
        }
        Mock Get-Process { @() }
        Mock Get-ItemProperty { $null }
        Mock Write-Warning
    }

    It 'uses bounded waits for normally exiting uninstall and taskkill children' {
        { & $script:ProcessExplorerCleanup } | Should -Not -Throw

        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*Uninstall Process Explorer.cmd' -and
            $ArgumentList -eq '/silent' -and -not $Wait -and $PassThru
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\System32\taskkill.exe' -and
            @($ArgumentList).Count -eq 2 -and
            $ArgumentList[0] -eq '/IM' -and $ArgumentList[1] -eq 'taskmgr.exe' -and
            -not $Wait -and $PassThru
        }
        $UninstallProcessStub.WaitTimeoutMilliseconds | Should -Be 300000
        $TaskkillProcessStub.WaitTimeoutMilliseconds | Should -Be 30000
    }

    It 'blocks removal when the uninstall child exceeds its bounded wait' {
        $UninstallProcessStub.Completes = $false

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*did not exit within 300 seconds*completion is unknown*payload removal is blocked*'

        Should -Invoke Start-Process -Times 0 -Exactly -ParameterFilter {
            $FilePath -like '*\System32\taskkill.exe'
        }
    }

    It 'blocks removal when taskkill exceeds its bounded wait' {
        $TaskkillProcessStub.Completes = $false

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*did not exit within 30 seconds*completion is unknown*payload removal is blocked*'
    }

    It 'throws when the uninstall child fails' {
        $UninstallProcessStub.ExitCode = 23

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*uninstall failed with exit code 23*'
    }

    It 'throws when taskkill returns an unexpected failure' {
        $TaskkillProcessStub.ExitCode = 5

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*taskkill.exe failed*exit code 5*'
    }

    It 'throws when Task Manager remains alive after taskkill reports success' {
        Mock Get-Process { [pscustomobject]@{ ProcessName = 'taskmgr'; Id = 42 } } -ParameterFilter {
            @($Name) -contains 'taskmgr'
        }

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*Task Manager is still running*'
    }

    It 'throws when an Atlas-installed Process Explorer process still owns the old payload' {
        $atlasProcessPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Apps\ProcessExplorer\procexp64.exe'
        Mock Get-Process {
            [pscustomobject]@{ ProcessName = 'procexp64'; Id = 84; Path = $atlasProcessPath }
        } -ParameterFilter {
            @($Name) -contains 'procexp64'
        }

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*still running from the Atlas payload*'
    }

    It 'fails closed when a Process Explorer process path cannot be verified' {
        Mock Get-Process {
            [pscustomobject]@{ ProcessName = 'procexp64'; Id = 126 }
        } -ParameterFilter {
            @($Name) -contains 'procexp64'
        }

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*still running from the Atlas payload*'
    }

    It 'throws when Task Manager still redirects into the old Process Explorer payload' {
        $debuggerPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Apps\ProcessExplorer\procexp.exe'
        Mock Get-ItemProperty { [pscustomobject]@{ Debugger = $debuggerPath } }

        { & $script:ProcessExplorerCleanup } |
            Should -Throw -ExpectedMessage '*still redirects to the Atlas Process Explorer payload*'
    }

    It 'halts the AME shim on cleanup failure before old payload removal' {
        $yaml = Get-Content -LiteralPath $script:CustomYaml -Raw
        $cleanupIndex = $yaml.IndexOf('Stop-ProcessExplorerUpgrade.ps1', [StringComparison]::Ordinal)
        $removalIndex = $yaml.IndexOf('Remove-PreviousAtlasInstall.ps1', [StringComparison]::Ordinal)

        $cleanupIndex | Should -BeGreaterOrEqual 0
        $removalIndex | Should -BeGreaterThan $cleanupIndex
        $cleanupBlock = $yaml.Substring($cleanupIndex, $removalIndex - $cleanupIndex)
        $cleanupBlock | Should -Match 'wait:\s*true'
        $cleanupBlock | Should -Match 'handleExitCodes:\s*\{\s*"!0":\s*halt\s*\}'
    }
}
