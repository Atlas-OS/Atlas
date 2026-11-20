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

$scriptsRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
$trustBootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$shellManifest = [IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Shell', 'Atlas.Shell.psd1')
$coreManifest = [IO.Path]::Combine($scriptsRoot, 'Modules', 'Atlas.Core', 'Atlas.Core.psd1')
foreach ($manifest in @($coreManifest, $shellManifest)) {
    if (-not [IO.File]::Exists($manifest)) {
        throw "The protected module manifest is missing at '$manifest'."
    }
    Microsoft.PowerShell.Core\Import-Module -Name $manifest -ErrorAction Stop
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
        throw "PowerShell didn't load Appx from its protected inbox module directory."
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
        throw "A registered Microsoft Store Windows Terminal package wasn't found for this user."
    }

    $installPath = [IO.Path]::GetFullPath([string]$selectedPackage.InstallLocation)
    if (-not [IO.Directory]::Exists($installPath)) {
        throw "The registered Windows Terminal package directory doesn't exist: '$installPath'."
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

function Start-AtlasTerminalProcess {
    param(
        [Parameter(Mandatory = $true)]
        [Diagnostics.ProcessStartInfo]$StartInfo
    )

    # Not Start-Process: it resolves -WorkingDirectory as a wildcard path, so a folder
    # such as 'Movies [2020]' fails or opens a sibling that matches the pattern.
    return [Diagnostics.Process]::Start($StartInfo)
}

function Show-AtlasTerminalFailure {
    <#
    .SYNOPSIS
        Logs why no terminal opened and tells the user. Explorer starts this handler
        without a window, so its own error is never seen.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Management.Automation.ErrorRecord]$ErrorRecord
    )

    $reason = $ErrorRecord.Exception.GetBaseException().Message
    # Neither report may replace the original error.
    try {
        Write-AtlasLog -Level Error -Message "Couldn't open $Terminal at '$Path': $reason" -ErrorRecord $ErrorRecord
    }
    catch {
        $null = $_
    }
    try {
        & ([IO.Path]::Combine($scriptsRoot, 'Operations', 'Show-AtlasToast.ps1')) `
            -Title Atlas -Message "Couldn't open the terminal. $reason"
    }
    catch {
        $null = $_
    }
}

try {
    if (-not [IO.Path]::IsPathRooted($Path) -or $Path.Length -gt 32767) {
        throw 'The terminal working directory must be one absolute path of at most 32,767 characters.'
    }

    # The verbs pass "%V." so a drive root's trailing backslash can't escape the
    # closing quote; GetFullPath drops the dot.
    try {
        $canonicalPath = [IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "The terminal working directory is invalid: '$Path'."
    }

    if (-not [IO.Directory]::Exists($canonicalPath)) {
        throw "The terminal working directory doesn't exist: '$canonicalPath'."
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

    # The arguments are fixed switches and a path ConvertTo-AtlasShellWindowsArgument
    # has quoted, so a plain join is the command line.
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $executablePath
    $startInfo.Arguments = $argumentList -join ' '
    $startInfo.WorkingDirectory = $canonicalPath
    $startInfo.UseShellExecute = $true
    $startInfo.Verb = $Verb

    $process = Start-AtlasTerminalProcess -StartInfo $startInfo
    if ($null -eq $process) {
        throw "Failed to start $Terminal at '$canonicalPath'."
    }
}
catch {
    # Declining the UAC prompt of an Admin entry is the user's choice, not a failure.
    $baseException = $_.Exception.GetBaseException()
    if ($baseException -is [ComponentModel.Win32Exception] -and $baseException.NativeErrorCode -eq 1223) {
        return
    }
    Show-AtlasTerminalFailure -ErrorRecord $_
    throw
}
