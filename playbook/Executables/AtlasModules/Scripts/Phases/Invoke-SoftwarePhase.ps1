# Software phase.
# Installs machine-wide initial utilities and the selected browser/toolbox. Runs as
# TrustedInstaller; downloads happen here at install time.
# Every selected component is attempted. Any failures are reported together
# after the remaining selections have had their installation attempt.

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop

$context = Get-AtlasContext
$requestedComponents = New-Object 'Collections.Generic.List[string]'
$failedComponents = New-Object 'Collections.Generic.List[string]'

# Initial software: Visual C++ Runtimes, NanaZip/7-Zip, DirectX (fresh installs only)
if (-not $context.IsUpgrade) {
    foreach ($component in @('VCRedist', 'SevenZip', 'DirectX')) {
        $requestedComponents.Add($component)
    }
}

# Toolbox
if (Test-AtlasOption -Name 'install-toolbox') {
    $requestedComponents.Add('Toolbox')
}

# Browsers ('browser-*' options are only set when 'install-another-browser' was picked;
# AME Wizard resolves that dependency before the option flags are written)
if (Test-AtlasOption -Name 'browser-brave') {
    $requestedComponents.Add('Brave')
}
if (Test-AtlasOption -Name 'browser-firefox') {
    $requestedComponents.Add('Firefox')
}
if (Test-AtlasOption -Name 'browser-librewolf') {
    $requestedComponents.Add('LibreWolf')
}
if (Test-AtlasOption -Name 'browser-chrome') {
    $requestedComponents.Add('Chrome')
}

foreach ($component in $requestedComponents) {
    try {
        $componentInstalled = [bool](Install-AtlasSoftware -Component $component)
        if (-not $componentInstalled) {
            throw "The '$component' installer reported an unsuccessful outcome."
        }

        if ($component -ceq 'LibreWolf' -and -not $context.IsOobe) {
            $interactiveUserSid = [string]$context.InteractiveUserSid
            if ([string]::IsNullOrWhiteSpace($interactiveUserSid)) {
                throw 'LibreWolf user integration requires the install-state user SID.'
            }

            $powerShellPath = [IO.Path]::Combine(
                [Environment]::SystemDirectory,
                'WindowsPowerShell',
                'v1.0',
                'powershell.exe'
            )
            $userIntegration = Join-Path -Path (Split-Path -Parent $PSScriptRoot) `
                -ChildPath 'Internal\Initialize-AtlasLibreWolfUser.ps1'
            if (-not (Test-Path -LiteralPath $userIntegration -PathType Leaf)) {
                throw "The LibreWolf user-integration helper is missing at '$userIntegration'."
            }
            $arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -ExpectedUserSid "{1}"' -f `
                $userIntegration,
                $interactiveUserSid
            $exitCode = Invoke-AtlasAsUser -FilePath $powerShellPath -Arguments $arguments
            if ($exitCode -ne 0) {
                throw "Exact-user LibreWolf integration failed with exit code $exitCode."
            }
        }
    }
    catch {
        if ($component -ceq 'DirectX') {
            Write-AtlasLog -Level Warning -Message `
                "Optional legacy DirectX runtime was not installed; continuing: $($_.Exception.Message)"
            continue
        }
        if (-not $failedComponents.Contains($component)) {
            $failedComponents.Add($component)
        }
        Write-AtlasLog -Level Warning -Message `
            "Software phase component '$component' failed: $($_.Exception.Message)"
    }
}

if ($failedComponents.Count -gt 0) {
    throw "Software phase failed for components: $($failedComponents -join ', ')."
}
