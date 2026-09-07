BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
}

Describe 'Preparation module boundary' {
    It '<Entry> resolves Appx from the inbox despite an inherited shadow module' -TestCases @(
        @{ Entry = 'playbook\Executables\AtlasModules\Scripts\Preparation\Update-Windows.ps1'; Staging = $false }
        @{ Entry = 'app\resources\prepare\Stage-App.ps1'; Staging = $true }
    ) {
        param($Entry, $Staging)
        $worker = Join-Path $script:AtlasTestRepoRoot $Entry
        $fixtureRoot = Join-Path $TestDrive 'module-boundary'
        $shadowRoot = Join-Path $fixtureRoot 'modules'
        $shadowModule = Join-Path $shadowRoot 'Appx'
        $marker = Join-Path $fixtureRoot 'shadow-imported.txt'
        [IO.Directory]::CreateDirectory($shadowModule) | Out-Null
        [IO.File]::WriteAllText((Join-Path $shadowModule 'Appx.psd1'), "@{ RootModule = 'Appx.psm1'; ModuleVersion = '99.0.0'; FunctionsToExport = @('Get-AppxPackage') }")
        [IO.File]::WriteAllText((Join-Path $shadowModule 'Appx.psm1'), @'
[IO.File]::WriteAllText($env:ATLAS_MODULE_TEST_MARKER, 'imported')
function Get-AppxPackage { [IO.File]::WriteAllText($env:ATLAS_MODULE_TEST_MARKER, 'executed') }
Export-ModuleMember -Function Get-AppxPackage
'@)
        $child = Join-Path $fixtureRoot 'probe.ps1'
        [IO.File]::WriteAllText($child, @'
param([string]$Worker, [string]$JobPath, [switch]$Control, [string]$ProbeKind)
$ErrorActionPreference = 'Stop'
trap { [Console]::Error.WriteLine(($_ | Out-String) + $_.ScriptStackTrace); exit 1 }
if (-not $Control) {
    if ($ProbeKind -eq 'stage') { . $Worker -FunctionsOnly }
    else { . $Worker -JobPath $JobPath -FunctionsOnly }
}
# Discovery imports the module, but never runs Get-AppxPackage or servicing.
$command = Get-Command -Name Get-AppxPackage -ErrorAction Stop
[Console]::WriteLine('MODULE:' + $command.Module.Path)
[Console]::WriteLine('PATH:' + $env:PSModulePath)
'@)
        $savedPath = $env:PSModulePath
        $savedMarker = $env:ATLAS_MODULE_TEST_MARKER
        try {
            $env:PSModulePath = $shadowRoot + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
            $env:ATLAS_MODULE_TEST_MARKER = $marker
            $control = & (Join-Path $PSHOME 'powershell.exe') -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $child -Control
            $LASTEXITCODE | Should -Be 0
            ($control -join "`n") | Should -Match ([regex]::Escape($shadowModule))
            [IO.File]::ReadAllText($marker) | Should -BeExactly 'imported'
            [IO.File]::Delete($marker)
            $probeKind = if ($Staging) { 'stage' } else { 'worker' }
            $output = & (Join-Path $PSHOME 'powershell.exe') -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $child -Worker $worker -JobPath $fixtureRoot -ProbeKind $probeKind
            $LASTEXITCODE | Should -Be 0
            ($output -join "`n") | Should -Match ('MODULE:' + [regex]::Escape((Join-Path $env:WINDIR 'Microsoft.Net\assembly\GAC_MSIL\Microsoft.Windows.Appx.PackageManager.Commands\')))
            ($output -join "`n") | Should -Not -Match ([regex]::Escape($shadowRoot))
            [IO.File]::Exists($marker) | Should -BeFalse
        }
        finally {
            $env:PSModulePath = $savedPath
            $env:ATLAS_MODULE_TEST_MARKER = $savedMarker
        }
    }
}
