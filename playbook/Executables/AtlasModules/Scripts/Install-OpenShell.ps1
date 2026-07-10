[CmdletBinding()]
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

# AtlasDesktop's .cmd file is a compatibility shim only. It captures one legacy
# token as data; validate it here and never replay its command text through UAC.
$launcherArgument = [Environment]::GetEnvironmentVariable(
    'AtlasLauncherArgument',
    [EnvironmentVariableTarget]::Process
)
[Environment]::SetEnvironmentVariable(
    'AtlasLauncherArgument',
    $null,
    [EnvironmentVariableTarget]::Process
)
if (-not [string]::IsNullOrEmpty($launcherArgument)) {
    if (-not $launcherArgument.Equals('/silent', [StringComparison]::OrdinalIgnoreCase) -and
        -not $launcherArgument.Equals('-silent', [StringComparison]::OrdinalIgnoreCase)) {
        [Console]::Error.WriteLine("Unsupported Open-Shell launcher argument '$launcherArgument'.")
        exit 2
    }
    $Silent = $true
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdministrator = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
$identity.Dispose()

if (-not $isAdministrator) {
    [Console]::Error.WriteLine('Administrator privileges are required to install Open-Shell.')
    exit 1
}

$trustBootstrap = [IO.Path]::Combine(
    $PSScriptRoot,
    'Internal',
    'Initialize-PowerShellTrust.ps1'
)
if (-not [IO.File]::Exists($trustBootstrap)) {
    [Console]::Error.WriteLine("The PowerShell trust bootstrap is missing at '$trustBootstrap'.")
    exit 1
}
. $trustBootstrap

try {
    $packageInstaller = [IO.Path]::Combine(
        $PSScriptRoot,
        'Internal',
        'Install-OpenShellPackage.ps1'
    )
    $themeInstaller = [IO.Path]::Combine(
        $PSScriptRoot,
        'Internal',
        'Install-OpenShellTheme.ps1'
    )
    if (-not [IO.File]::Exists($packageInstaller) -or
        -not [IO.File]::Exists($themeInstaller)) {
        throw 'One or more protected Open-Shell installer helpers are missing.'
    }

    Write-Output 'Downloading and installing Open-Shell...'
    $packageResult = & $packageInstaller
    if ($null -eq $packageResult -or
        $packageResult.PSObject.Properties.Name -notcontains 'RebootRequired') {
        throw 'The Open-Shell package helper did not return its typed installation result.'
    }

    $themeFailure = $null
    try {
        & $themeInstaller
    }
    catch {
        $themeFailure = $_.Exception.Message
        Write-Warning "The pinned Fluent Metro theme could not be installed: $themeFailure"
    }

    if ($null -ne $themeFailure) {
        [Console]::Error.WriteLine(
            "Open-Shell was installed, but its pinned Fluent Metro theme failed transactionally: $themeFailure"
        )
        if (-not $Silent) {
            [void](Read-Host 'Press Enter to exit')
        }
        exit 3
    }

    Write-Output 'Finished, changes have been applied.'
    if (-not $Silent) {
        [void](Read-Host 'Press Enter to exit')
    }
    if ([bool]$packageResult.RebootRequired) {
        [Console]::Error.WriteLine('Open-Shell was installed and requires a restart.')
        exit 3010
    }
    exit 0
}
catch {
    Write-Error "Installing Open-Shell failed: $($_.Exception.Message)" -ErrorAction Continue
    if (-not $Silent) {
        [void](Read-Host 'Press Enter to exit')
    }
    exit 1
}
