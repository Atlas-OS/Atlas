BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:PowerShell51 = Join-Path $PSHOME 'powershell.exe'
    $broker = Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasTrustedInstallerBroker.ps1'
    $ast = [Management.Automation.Language.Parser]::ParseFile($broker, [ref]$null, [ref]$null)
    $reader = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-AtlasInstallFailureDetail' }, $true)
    . ([scriptblock]::Create($reader.Extent.Text))
}

Describe 'Early TrustedInstaller install evidence' {
    It 'retains install-plan host output and warnings and preserves its exit code' {
        $scripts = Join-Path $TestDrive 'run\AtlasModules\Scripts'
        foreach ($directory in @('Install', 'Entry', 'Modules\Atlas.Core', 'Modules\Atlas.InstallState')) {
            New-Item -ItemType Directory -Path (Join-Path $scripts $directory) -Force | Out-Null
        }
        $entry = Join-Path $scripts 'Install\Invoke-AtlasInstallSession.ps1'
        Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Install\Invoke-AtlasInstallSession.ps1') $entry
        Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') $scripts
        foreach ($name in @('Atlas.Core', 'Atlas.InstallState')) {
            Set-Content (Join-Path $scripts "Modules\$name\$name.psd1") "@{ RootModule = '$name.psm1'; ModuleVersion = '1.0.0' }"
            Set-Content (Join-Path $scripts "Modules\$name\$name.psm1") 'function Assert-AtlasPrivilege { param([switch]$TrustedInstaller) }'
        }
        Set-Content (Join-Path $scripts 'Entry\Initialize-AtlasInstallState.ps1') 'param($Operation)'
        Set-Content (Join-Path $scripts 'Entry\Invoke-AtlasInstall.ps1') @'
param([switch]$Run)
Write-Host 'Visual C++ Runtime fixture failed with exit code 1638.'
Write-Warning 'fixture warning'
exit 37
'@
        & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $entry -Phase Run
        $LASTEXITCODE | Should -Be 37
        $detail = Get-AtlasInstallFailureDetail -PayloadRoot (Join-Path $TestDrive 'run') -Phase Run
        $detail | Should -Match 'Visual C\+\+ Runtime fixture failed with exit code 1638'
        $detail | Should -Match 'fixture warning'
        $detail | Should -Match 'Install plan exited with code 37'
    }

    It 'persists <Failure> errors without inherited output and exposes them to the broker' -TestCases @(
        @{ Failure = 'bootstrap' }
        @{ Failure = 'module' }
    ) {
        param($Failure)
        $payload = Join-Path $TestDrive $Failure
        $scripts = Join-Path $payload 'AtlasModules\Scripts'
        $install = Join-Path $scripts 'Install'
        New-Item -ItemType Directory -Path $install -Force | Out-Null
        $entry = Join-Path $install 'Invoke-AtlasInstallSession.ps1'
        Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Install\Invoke-AtlasInstallSession.ps1') $entry
        if ($Failure -eq 'module') {
            Copy-Item (Join-Path $script:AtlasTestScriptsRoot 'Initialize-AtlasPowerShell.ps1') $scripts
            $core = Join-Path $scripts 'Modules\Atlas.Core'
            New-Item -ItemType Directory -Path $core -Force | Out-Null
            Set-Content (Join-Path $core 'Atlas.Core.psd1') "@{ RootModule = 'Atlas.Core.psm1'; ModuleVersion = '1.0.0' }"
            Set-Content (Join-Path $core 'Atlas.Core.psm1') "throw 'fixture module import failed'"
        }
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = $script:PowerShell51
        $start.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $entry + '" -Phase Capture'
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $process = [Diagnostics.Process]::Start($start)
        try {
            $process.WaitForExit(30000) | Should -BeTrue
            $process.ExitCode | Should -Be 1
        }
        finally { $process.Dispose() }
        $detail = Get-AtlasInstallFailureDetail -PayloadRoot $payload -Phase Capture
        $detail | Should -Match 'Starting install phase Capture'
        $detail | Should -Match 'ERROR:'
        if ($Failure -eq 'module') { $detail | Should -Match 'fixture module import failed' }
        else { $detail | Should -Match 'PowerShell bootstrap is missing' }
        $detail | Should -Match 'Invoke-AtlasInstallSession.ps1'
    }

    It 'bounds failure output while retaining the final exception' {
        $payload = Join-Path $TestDrive 'bounded'
        $logs = Join-Path $payload 'AtlasModules\Logs'
        New-Item -ItemType Directory -Path $logs -Force | Out-Null
        $path = Join-Path $logs 'install-capture.log'
        [IO.File]::WriteAllText($path, ('x' * 20000) + 'final exception')
        $detail = Get-AtlasInstallFailureDetail -PayloadRoot $payload -Phase Capture
        $detail.Length | Should -Be 16384
        $detail | Should -Match 'final exception$'
    }

    It 'collects old RC state into app logs without modifying the source files' {
        $windows = Join-Path $TestDrive 'Windows'
        $app = Join-Path $TestDrive 'App'
        $state = Join-Path $windows 'AtlasOS\Install'
        $payload = Join-Path $windows 'AtlasOS\Staging\one\Executables'
        New-Item -ItemType Directory -Path $state, $payload, $app -Force | Out-Null
        $active = Join-Path $state 'active.json'
        $request = Join-Path $payload 'request.json'
        $original = '{"status":"Running","options":["install-toolbox"]}'
        [IO.File]::WriteAllText($active, $original)
        [IO.File]::WriteAllText($request, '{"options":[]}')
        $legacyLogs = Join-Path $payload 'AtlasModules\Logs\install'
        New-Item -ItemType Directory -Path $legacyLogs -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $legacyLogs 'atlas-install.log'), 'Visual C++ Runtime fixture failed with exit code 1234.')
        & $script:PowerShell51 -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `
            (Join-Path $script:AtlasTestRepoRoot 'tools\dev\Get-AtlasInstallEvidence.ps1') -WindowsRoot $windows -AppRoot $app
        $LASTEXITCODE | Should -Be 0
        $log = Get-ChildItem (Join-Path $app 'Logs') -Filter '*.log'
        $text = Get-Content $log.FullName -Raw
        $text | Should -Match 'install-toolbox'
        $text | Should -Match 'request.json'
        $text | Should -Match 'Visual C\+\+ Runtime fixture failed with exit code 1234'
        $text | Should -Match 'Unavailable:'
        [IO.File]::ReadAllText($active) | Should -Be $original
        [IO.File]::ReadAllText($request) | Should -Be '{"options":[]}'
    }
}
