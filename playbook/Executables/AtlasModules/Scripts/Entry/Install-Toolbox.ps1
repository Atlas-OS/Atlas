[CmdletBinding()]
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

# The .cmd compatibility launcher passes only its first token through a process
# environment slot. Normalize it here, then clear it before any elevated child
# is created; no caller-supplied command text crosses the UAC boundary.
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
        [Console]::Error.WriteLine("Unsupported Toolbox launcher argument '$launcherArgument'.")
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
    [Console]::Error.WriteLine('Administrator privileges are required to install Toolbox.')
    exit 1
}

$scriptsRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
$trustBootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

$title = 'Install AtlasOS Toolbox'
$coreManifest = [IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Core', 'Atlas.Core.psd1')
Import-Module -Name $coreManifest -ErrorAction Stop
if (-not $Silent) {
    Set-AtlasLogConsoleStyle -Style Interactive
    Write-AtlasTitle -Text $title -Explanation 'Downloads and installs the latest AtlasOS Toolbox release from GitHub.'
}

try {
    $packageHelper = [IO.Path]::Combine($scriptsRoot, 'Operations', 'Toolbox-Package.ps1')
    if (-not [IO.File]::Exists($packageHelper)) {
        throw "The protected Toolbox package helper is missing at '$packageHelper'."
    }
    . $packageHelper
    Install-AtlasToolboxPackage

    if (-not $Silent) {
        Write-AtlasCompletion -Title $title
        Wait-AtlasExit
    }
    exit 0
}
catch {
    Write-AtlasLog -Level Error -Message "Installing AtlasOS Toolbox failed: $($_.Exception.Message)" -ErrorRecord $_ -NoConsole:(-not $Silent)
    if (-not $Silent) {
        Write-AtlasNotApplied -Title $title -Reason $_.Exception.Message -DetailsPath (Get-AtlasInstallLogPath)
        Wait-AtlasExit
    }
    exit 1
}
