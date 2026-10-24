BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:ScriptsRoot = $script:AtlasTestScriptsRoot
    $script:PowerShell51 = [IO.Path]::Combine(
        [Environment]::SystemDirectory,
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe'
    )

    # Rehost the real entry script next to a stub toggle engine, so its process
    # behavior (arguments, logging, exit code) runs without any real toggle.
    # Invoke-Toggle.ps1 finds the bootstrap and modules relative to its own folder.
    $harnessRoot = Join-Path $TestDrive 'Harness'
    $harnessScripts = Join-Path $harnessRoot 'Scripts'
    $null = New-Item -Path (Join-Path $harnessScripts 'Entry') -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $harnessScripts 'Modules\Atlas.Toggles') `
        -ItemType Directory -Force
    $null = New-Item -Path (Join-Path $harnessScripts 'Modules\Atlas.Core') `
        -ItemType Directory -Force
    Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot 'Entry\Invoke-Toggle.ps1') `
        -Destination (Join-Path $harnessScripts 'Entry\Invoke-Toggle.ps1')
    Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot 'Initialize-AtlasPowerShell.ps1') `
        -Destination (Join-Path $harnessScripts 'Initialize-AtlasPowerShell.ps1')

    # The entry script imports Atlas.Core before the engine; the stub keeps the
    # commands it calls. Like the real logger, only the Interactive console style
    # honours -NoConsole, and the exit pause prints a marker instead of waiting.
    Set-Content -LiteralPath (Join-Path $harnessScripts 'Modules\Atlas.Core\Atlas.Core.psd1') `
        -Encoding Ascii -Value @'
@{
    RootModule        = 'Atlas.Core.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6f2f2d1a-2b1c-4d7e-9c2a-0d1e7f3b5a90'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Set-AtlasLogConsoleStyle', 'Write-AtlasLog', 'Get-AtlasInstallLogPath', 'Write-AtlasNotApplied', 'Wait-AtlasExit')
}
'@
    Set-Content -LiteralPath (Join-Path $harnessScripts 'Modules\Atlas.Core\Atlas.Core.psm1') `
        -Encoding Ascii -Value @'
$script:consoleStyle = 'Diagnostic'
function Set-AtlasLogConsoleStyle { param([string]$Style) $script:consoleStyle = $Style }
function Write-AtlasLog {
    param([string]$Message, [string]$Level = 'Info', $ErrorRecord, [switch]$NoConsole)
    if (-not ($NoConsole -and $script:consoleStyle -eq 'Interactive')) {
        Write-Output "[$($Level.ToUpperInvariant())] $Message"
    }
}
function Get-AtlasInstallLogPath { 'C:\harness\atlas-install.log' }
function Write-AtlasNotApplied { param([string]$Title, [string]$Reason, [string]$DetailsPath) Write-Output "Not applied: $Title. $Reason" }
function Wait-AtlasExit { param([string]$Message) Write-Output 'harness exit pause' }
'@
    Set-Content -LiteralPath (Join-Path $harnessScripts 'Modules\Atlas.Toggles\Atlas.Toggles.psd1') `
        -Encoding Ascii -Value @'
@{
    RootModule        = 'Atlas.Toggles.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '0a1b6f0e-64f1-4dfc-9e34-b2f2a49d6f21'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-AtlasToggle')
}
'@
    Set-Content -LiteralPath (Join-Path $harnessScripts 'Modules\Atlas.Toggles\Atlas.Toggles.psm1') `
        -Encoding Ascii -Value @'
function Invoke-AtlasToggle {
    param(
        $Name,
        $State,
        $LauncherPath,
        [bool]$Silent,
        [bool]$JustContext,
        [bool]$NoExplorerRestart,
        [bool]$MachineOnly
    )

    switch ($Name) {
        'HarnessSuccess' {
            Write-Output "harness applied '$Name' state '$State' silent=$Silent machineOnly=$MachineOnly"
            return
        }
        'HarnessFailure' {
            throw 'harness toggle failure'
        }
        'HarnessAdminChild' {
            $exception = New-Object Exception 'the elevated toggle child failed'
            $exception.Data['Atlas.Toggle.AdminChildExitCode'] = 5
            throw $exception
        }
        default {
            throw "Unknown toggle '$Name'."
        }
    }
}
'@

    $script:EntryScript = Join-Path $harnessScripts 'Entry\Invoke-Toggle.ps1'
    function Invoke-ToggleEntry {
        param([Parameter(Mandatory = $true)][string[]]$Arguments)

        $output = & $script:PowerShell51 -NoProfile -NoLogo -NonInteractive `
            -ExecutionPolicy Bypass -File $script:EntryScript @Arguments 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output   = ($output | Out-String)
        }
    }
}

Describe 'Toggle CLI entry point exit and logging contract' {
    It 'exits zero when the toggle engine succeeds' {
        $result = Invoke-ToggleEntry -Arguments @(
            '-Name', 'HarnessSuccess', '-State', 'On', '-LauncherPath', 'C:\fake.cmd', '/silent'
        )

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match "harness applied 'HarnessSuccess' state 'On' silent=True machineOnly=False"
    }

    It 'forwards -MachineOnly to the engine for the privileged child of a split state' {
        $result = Invoke-ToggleEntry -Arguments @(
            '-Name', 'HarnessSuccess', '-State', 'On', '-MachineOnly', '/silent'
        )

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match "harness applied 'HarnessSuccess' state 'On' silent=True machineOnly=True"
    }

    It 'exits nonzero and still emits the failure when the toggle throws silently' {
        $result = Invoke-ToggleEntry -Arguments @('-Name', 'HarnessFailure', '/silent')

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match `
            "Applying toggle 'HarnessFailure' failed: harness toggle failure"
        # A silent caller has no window to explain the failure in or pause.
        $result.Output | Should -Not -Match 'Not applied:'
        $result.Output | Should -Not -Match 'harness exit pause'
    }

    It 'shows an interactive failure once, then pauses before exiting nonzero' {
        $result = Invoke-ToggleEntry -Arguments @('-Name', 'HarnessFailure')

        $result.ExitCode | Should -Be 1 -Because $result.Output
        $lines = @($result.Output -split '\r?\n' | Where-Object { $_ })
        @($lines | Where-Object { $_ -ceq 'Not applied: HarnessFailure. harness toggle failure' }) |
            Should -HaveCount 1 -Because $result.Output
        @($lines | Where-Object { $_ -ceq 'harness exit pause' }) | Should -HaveCount 1 -Because $result.Output
        $lines[-1] | Should -BeExactly 'harness exit pause'
        # The failure block already gives the reason; the log line stays off the console.
        $result.Output | Should -Not -Match '\[ERROR\]'
    }

    It 'exits nonzero when no toggle name is supplied' {
        $result = Invoke-ToggleEntry -Arguments @('/silent')

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'requires -Name'
    }

    It 'propagates a recorded elevated-child exit code unchanged' {
        $result = Invoke-ToggleEntry -Arguments @('-Name', 'HarnessAdminChild', '/silent')

        $result.ExitCode | Should -Be 5
        $result.Output | Should -Match 'the elevated toggle child failed'
    }
}
