BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
    $script:AtlasModulesRoot = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Executables\AtlasModules'
    $script:ScriptsRoot = Join-Path -Path $script:AtlasModulesRoot -ChildPath 'Scripts'
    $script:ModulesRoot = Join-Path -Path $script:ScriptsRoot -ChildPath 'Modules'
    $script:InitScript = Join-Path -Path $script:AtlasModulesRoot -ChildPath 'initPowerShell.ps1'

    $script:CurrentPowerShell = if ($PSVersionTable.PSEdition -eq 'Desktop') {
        Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
    }
    else {
        Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
    }
}

Describe 'Protected Atlas module resolution' {
    It 'puts the canonical Atlas module root first and de-duplicates it' {
        $separator = [IO.Path]::PathSeparator
        $shadowRoot = Join-Path -Path $TestDrive -ChildPath 'ShadowModules'
        $originalModulePath = $env:PSModulePath

        try {
            $env:PSModulePath = @($shadowRoot, $script:ModulesRoot, $shadowRoot) -join $separator
            & $script:InitScript

            $paths = @($env:PSModulePath -split [regex]::Escape([string]$separator) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            $paths[0] | Should -Be $script:ModulesRoot
            @($paths | Where-Object { $_ -ieq $script:ModulesRoot }).Count | Should -Be 1
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'runs the install entrypoint from its adjacent manifest when a shadow module is first' {
        $sandboxRoot = Join-Path -Path $TestDrive -ChildPath 'ProtectedPayload'
        $sandboxScripts = Join-Path -Path $sandboxRoot -ChildPath 'Scripts'
        $sandboxModules = Join-Path -Path $sandboxScripts -ChildPath 'Modules'
        $canonicalModule = Join-Path -Path $sandboxModules -ChildPath 'Atlas.Core'
        $shadowRoot = Join-Path -Path $TestDrive -ChildPath 'AttackerModules'
        $shadowModule = Join-Path -Path $shadowRoot -ChildPath 'Atlas.Core'
        $sandboxPhases = Join-Path -Path $sandboxScripts -ChildPath 'Phases'

        foreach ($directory in @($canonicalModule, $shadowModule, $sandboxPhases)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        Copy-Item -LiteralPath (Join-Path $script:ScriptsRoot 'Invoke-AtlasInstall.ps1') `
            -Destination (Join-Path $sandboxScripts 'Invoke-AtlasInstall.ps1')
        Copy-Item -LiteralPath $script:InitScript -Destination (Join-Path $sandboxRoot 'initPowerShell.ps1')
        Set-Content -LiteralPath (Join-Path $sandboxPhases 'Invoke-RevertPhase.ps1') -Value '' -Encoding UTF8

        @'
Set-Content -LiteralPath $env:ATLAS_CANONICAL_MODULE_MARKER -Value 'canonical'
function Start-AtlasPhase { param([string]$Phase, [string]$Category) }
function Stop-AtlasPhase {}
function Write-AtlasLog { param([string]$Level, [string]$Message, $ErrorRecord) }
Export-ModuleMember -Function Start-AtlasPhase, Stop-AtlasPhase, Write-AtlasLog
'@ | Set-Content -LiteralPath (Join-Path $canonicalModule 'Atlas.Core.psm1') -Encoding UTF8

        @'
Set-Content -LiteralPath $env:ATLAS_SHADOW_MODULE_MARKER -Value 'shadow'
function Start-AtlasPhase { param([string]$Phase, [string]$Category) }
function Stop-AtlasPhase {}
function Write-AtlasLog { param([string]$Level, [string]$Message, $ErrorRecord) }
Export-ModuleMember -Function Start-AtlasPhase, Stop-AtlasPhase, Write-AtlasLog
'@ | Set-Content -LiteralPath (Join-Path $shadowModule 'Atlas.Core.psm1') -Encoding UTF8

        $manifest = @'
@{
    RootModule = 'Atlas.Core.psm1'
    ModuleVersion = '1.0.0'
    GUID = '11111111-1111-1111-1111-111111111111'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-AtlasPhase', 'Stop-AtlasPhase', 'Write-AtlasLog')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
'@
        Set-Content -LiteralPath (Join-Path $canonicalModule 'Atlas.Core.psd1') -Value $manifest -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $shadowModule 'Atlas.Core.psd1') -Value $manifest -Encoding UTF8

        $canonicalMarker = Join-Path -Path $TestDrive -ChildPath 'canonical-module.txt'
        $shadowMarker = Join-Path -Path $TestDrive -ChildPath 'shadow-module.txt'
        $originalModulePath = $env:PSModulePath
        $originalCanonicalMarker = $env:ATLAS_CANONICAL_MODULE_MARKER
        $originalShadowMarker = $env:ATLAS_SHADOW_MODULE_MARKER

        try {
            $env:PSModulePath = $shadowRoot
            $env:ATLAS_CANONICAL_MODULE_MARKER = $canonicalMarker
            $env:ATLAS_SHADOW_MODULE_MARKER = $shadowMarker

            $output = & $script:CurrentPowerShell -NoProfile -ExecutionPolicy Bypass -File `
                (Join-Path $sandboxScripts 'Invoke-AtlasInstall.ps1') -Phase Revert 2>&1
            $processExitCode = $LASTEXITCODE
        }
        finally {
            $env:PSModulePath = $originalModulePath
            $env:ATLAS_CANONICAL_MODULE_MARKER = $originalCanonicalMarker
            $env:ATLAS_SHADOW_MODULE_MARKER = $originalShadowMarker
        }

        $processExitCode | Should -Be 0 -Because ($output -join "`n")
        $canonicalMarker | Should -Exist
        $shadowMarker | Should -Not -Exist
    }

    It '<RelativePath> imports Atlas modules by adjacent manifest path' -TestCases @(
        @{ RelativePath = 'Invoke-AtlasInstall.ps1'; Modules = @('Atlas.Core') }
        @{ RelativePath = 'Invoke-Toggle.ps1'; Modules = @('Atlas.Toggles') }
        @{ RelativePath = 'Install-AtlasPackage.ps1'; Modules = @('Atlas.Core', 'Atlas.Software') }
        @{ RelativePath = 'Phases\Invoke-AppxSupportPhase.ps1'; Modules = @('Atlas.Appx', 'Atlas.TasksProcs') }
        @{ RelativePath = 'Phases\Invoke-ComponentsPhase.ps1'; Modules = @('Atlas.Services', 'Atlas.TasksProcs', 'Atlas.Software') }
        @{ RelativePath = 'Phases\Invoke-DefaultsPhase.ps1'; Modules = @('Atlas.Toggles') }
        @{ RelativePath = 'Phases\Invoke-FinalizePhase.ps1'; Modules = @('Atlas.Registry') }
        @{ RelativePath = 'Phases\Invoke-RevertPhase.ps1'; Modules = @('Atlas.Registry', 'Atlas.Tweaks') }
        @{ RelativePath = 'Phases\Invoke-ServicesPhase.ps1'; Modules = @('Atlas.Services') }
        @{ RelativePath = 'Phases\Invoke-SoftwarePhase.ps1'; Modules = @('Atlas.Software') }
        @{ RelativePath = 'Phases\Invoke-TweaksPhase.ps1'; Modules = @('Atlas.Registry', 'Atlas.Tweaks') }
        @{ RelativePath = 'Tweaks\qol\config-start-menu.ps1'; Modules = @('Atlas.Appx') }
        @{ RelativePath = 'Tweaks\qol\shell\restore-old-context-menu.ps1'; Modules = @('Atlas.Registry') }
        @{ RelativePath = 'Tweaks\qol\shell\set-unpinned-notification-items.ps1'; Modules = @('Atlas.Registry') }
        @{ RelativePath = 'Tweaks\scripts\backup-services.ps1'; Modules = @('Atlas.Services') }
    ) {
        $source = Get-Content -LiteralPath (Join-Path $script:ScriptsRoot $RelativePath) -Raw
        $source | Should -Not -Match '(?im)^\s*Import-Module\s+(?:-Name\s+)?["'']?Atlas\.'

        foreach ($moduleName in $Modules) {
            $source | Should -Match ([regex]::Escape("$moduleName\$moduleName.psd1"))
        }
    }

    It 'does not import Atlas modules by name from inline privileged YAML commands' {
        $configurationRoot = Join-Path -Path $script:RepoRoot -ChildPath 'playbook\Configuration'
        $configurationText = (Get-ChildItem -LiteralPath $configurationRoot -Filter '*.yml' -File -Recurse |
            ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"

        $configurationText | Should -Not -Match 'Import-Module\s+(?:-Name\s+)?["'']?Atlas\.'
    }
}
