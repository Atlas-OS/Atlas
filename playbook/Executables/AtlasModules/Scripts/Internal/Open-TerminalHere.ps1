<#
.SYNOPSIS
    Opens one fixed terminal type at a validated directory.

.DESCRIPTION
    Explorer supplies the selected directory only as a process argument. The
    selected path is never incorporated into cmd.exe or PowerShell source.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CommandPrompt', 'PowerShell', 'WindowsTerminal')]
    [string]$Terminal,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Open', 'RunAs')]
    [string]$Verb,

    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$shellSupport = [IO.Path]::Combine($PSScriptRoot, 'Shell-ContextMenuSupport.ps1')
if (-not [IO.File]::Exists($shellSupport)) {
    throw "The protected shell context-menu support library is missing at '$shellSupport'."
}
. $shellSupport

if (-not [IO.Path]::IsPathRooted($Path) -or $Path.Length -gt 32767) {
    throw 'The terminal working directory must be one bounded absolute path.'
}

try {
    $canonicalPath = [IO.Path]::GetFullPath($Path)
}
catch {
    throw "The terminal working directory is invalid: '$Path'."
}

if (-not [IO.Directory]::Exists($canonicalPath)) {
    throw "The terminal working directory does not exist: '$canonicalPath'."
}

function Get-AtlasWindowsTerminalPath {
    $appxManifest = [IO.Path]::Combine($PSHOME, 'Modules', 'Appx', 'Appx.psd1')
    if (-not [IO.File]::Exists($appxManifest)) {
        throw "The protected inbox Appx module is missing at '$appxManifest'."
    }

    $loaded = @(Microsoft.PowerShell.Core\Import-Module -Name $appxManifest -Force -PassThru -ErrorAction Stop)
    $expectedAppxModuleBase = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($appxManifest)).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $loadedFromInbox = $false
    foreach ($module in $loaded) {
        if ($module.Name -eq 'Appx' -and
            [IO.Path]::GetFullPath($module.ModuleBase).TrimEnd(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ).Equals(
                $expectedAppxModuleBase,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            $loadedFromInbox = $true
            break
        }
    }
    if (-not $loadedFromInbox) {
        throw 'PowerShell did not load Appx from its protected inbox module directory.'
    }

    $selectedPackage = $null
    foreach ($package in @(Appx\Get-AppxPackage -Name 'Microsoft.WindowsTerminal' -ErrorAction Stop)) {
        if ($package.Name -cne 'Microsoft.WindowsTerminal' -or
            $package.PackageFamilyName -cne 'Microsoft.WindowsTerminal_8wekyb3d8bbwe' -or
            $package.PublisherId -cne '8wekyb3d8bbwe' -or
            [string]$package.SignatureKind -notin @('Store', 'System') -or
            [bool]$package.IsFramework -or
            [string]::IsNullOrWhiteSpace([string]$package.InstallLocation)) {
            continue
        }

        if ($null -eq $selectedPackage -or [version]$package.Version -gt [version]$selectedPackage.Version) {
            $selectedPackage = $package
        }
    }

    if ($null -eq $selectedPackage) {
        throw 'A registered Microsoft Store Windows Terminal package was not found for this user.'
    }

    $installPath = [IO.Path]::GetFullPath([string]$selectedPackage.InstallLocation)
    if (-not [IO.Directory]::Exists($installPath)) {
        throw "The registered Windows Terminal package directory does not exist: '$installPath'."
    }
    if (([IO.File]::GetAttributes($installPath) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The registered Windows Terminal package directory is a reparse point: '$installPath'."
    }

    $terminalPath = [IO.Path]::GetFullPath([IO.Path]::Combine($installPath, 'wt.exe'))
    $installPrefix = $installPath.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) +
        [IO.Path]::DirectorySeparatorChar
    if (-not $terminalPath.StartsWith($installPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not [IO.File]::Exists($terminalPath)) {
        throw "The registered Windows Terminal executable is missing from '$installPath'."
    }
    if (([IO.File]::GetAttributes($terminalPath) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The registered Windows Terminal executable is a reparse point: '$terminalPath'."
    }

    return $terminalPath
}

$argumentList = @()
switch ($Terminal) {
    'CommandPrompt' {
        $executablePath = [IO.Path]::Combine([Environment]::SystemDirectory, 'cmd.exe')
    }
    'PowerShell' {
        $executablePath = [IO.Path]::Combine(
            [Environment]::SystemDirectory,
            'WindowsPowerShell',
            'v1.0',
            'powershell.exe'
        )
        $argumentList = @('-NoLogo', '-NoExit')
    }
    'WindowsTerminal' {
        $executablePath = Get-AtlasWindowsTerminalPath
        $argumentList = @('-d', (ConvertTo-AtlasShellWindowsArgument -Value $canonicalPath))
    }
}

if (-not [IO.File]::Exists($executablePath)) {
    throw "The selected terminal executable is missing at '$executablePath'."
}

$startParameters = @{
    FilePath         = $executablePath
    WorkingDirectory = $canonicalPath
    Verb             = $Verb
    PassThru         = $true
}
if ($argumentList.Count -gt 0) {
    $startParameters.ArgumentList = $argumentList
}

$process = Microsoft.PowerShell.Management\Start-Process @startParameters
if ($null -eq $process) {
    throw "Failed to start $Terminal at '$canonicalPath'."
}
