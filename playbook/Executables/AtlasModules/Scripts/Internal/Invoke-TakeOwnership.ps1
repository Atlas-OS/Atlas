<#
.SYNOPSIS
    Applies the Atlas Take Ownership operation to one validated file-system path.

.DESCRIPTION
    The target path remains a native-process argument. It is never included in
    cmd.exe or PowerShell source, including across the UAC boundary.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('File', 'Directory', 'Drive')]
    [string]$TargetType,

    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,

    [switch]$Pause,

    [switch]$Elevated
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

if (-not [IO.Path]::IsPathRooted($TargetPath) -or $TargetPath.Length -gt 32767) {
    throw 'The Take Ownership target must be one bounded absolute path.'
}

try {
    $canonicalPath = [IO.Path]::GetFullPath($TargetPath)
}
catch {
    throw "The Take Ownership target path is invalid: '$TargetPath'."
}

switch ($TargetType) {
    'File' {
        if (-not [IO.File]::Exists($canonicalPath)) {
            throw "The Take Ownership file does not exist: '$canonicalPath'."
        }
    }
    'Directory' {
        if (-not [IO.Directory]::Exists($canonicalPath)) {
            throw "The Take Ownership directory does not exist: '$canonicalPath'."
        }
    }
    'Drive' {
        $rootPath = [IO.Path]::GetPathRoot($canonicalPath)
        if ([string]::IsNullOrWhiteSpace($rootPath) -or
            -not $canonicalPath.TrimEnd('\', '/').Equals(
                $rootPath.TrimEnd('\', '/'),
                [StringComparison]::OrdinalIgnoreCase
            ) -or
            -not [IO.Directory]::Exists($canonicalPath)) {
            throw "The Take Ownership drive target is not an existing file-system root: '$canonicalPath'."
        }
    }
}

if (([IO.File]::GetAttributes($canonicalPath) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "The Take Ownership target is a reparse point: '$canonicalPath'."
}

$powerShellPath = [IO.Path]::Combine(
    [Environment]::SystemDirectory,
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe'
)
if (-not [IO.File]::Exists($powerShellPath)) {
    throw "The inbox Windows PowerShell executable is missing at '$powerShellPath'."
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = Microsoft.PowerShell.Utility\New-Object Security.Principal.WindowsPrincipal($identity)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $Elevated) {
    $scriptPath = [IO.Path]::GetFullPath($PSCommandPath)
    if (-not [IO.File]::Exists($scriptPath)) {
        throw "The Take Ownership handler is missing at '$scriptPath'."
    }

    $childArguments = @(
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        (ConvertTo-AtlasShellWindowsArgument -Value $scriptPath),
        '-TargetType',
        $TargetType,
        '-TargetPath',
        (ConvertTo-AtlasShellWindowsArgument -Value $canonicalPath),
        '-Elevated'
    )
    if ($Pause) {
        $childArguments += '-Pause'
    }

    $child = Microsoft.PowerShell.Management\Start-Process `
        -FilePath $powerShellPath `
        -ArgumentList $childArguments `
        -Verb RunAs `
        -WindowStyle Normal `
        -Wait `
        -PassThru
    if ($child.ExitCode -ne 0) {
        throw "The elevated Take Ownership handler failed with exit code $($child.ExitCode)."
    }
    return
}

if (-not $isAdministrator) {
    throw 'The elevated Take Ownership handler does not have an administrator token.'
}

if ($TargetType -in @('Directory', 'Drive')) {
    # Fail closed before recursion if any currently reachable descendant is a
    # reparse point. /SKIPSL and icacls /l below provide the native no-follow
    # policy as well. The remaining path-namespace race is a live VM test gate.
    Assert-AtlasTakeOwnershipTree -RootPath $canonicalPath
}

$takeOwnPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'takeown.exe')
$icaclsPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'icacls.exe')
$choicePath = [IO.Path]::Combine([Environment]::SystemDirectory, 'choice.exe')
foreach ($requiredPath in @($takeOwnPath, $icaclsPath, $choicePath)) {
    if (-not [IO.File]::Exists($requiredPath)) {
        throw "A required inbox Take Ownership executable is missing at '$requiredPath'."
    }
}

$failure = $null
try {
    $yesChoice = $null
    if ($TargetType -in @('Directory', 'Drive')) {
        $choiceOutput = @($null | & $choicePath 2>$null)
        if ($choiceOutput.Count -lt 1 -or
            [string]::IsNullOrWhiteSpace([string]$choiceOutput[0]) -or
            ([string]$choiceOutput[0]).Length -lt 3 -or
            -not ([string]$choiceOutput[0]).StartsWith('[', [StringComparison]::Ordinal)) {
            throw 'Could not determine the localized affirmative response for takeown.exe.'
        }
        $yesChoice = ([string]$choiceOutput[0]).Substring(1, 1)
        if ([char]::IsWhiteSpace($yesChoice[0]) -or $yesChoice -eq '"') {
            throw 'The localized affirmative response for takeown.exe is invalid.'
        }
    }

    $argumentPlan = Get-AtlasTakeOwnershipArgumentPlan `
        -TargetType $TargetType `
        -TargetPath $canonicalPath `
        -YesChoice $yesChoice
    $takeOwnArguments = $argumentPlan.TakeOwnArguments
    $icaclsArguments = $argumentPlan.IcaclsArguments

    & $takeOwnPath @takeOwnArguments
    if ($LASTEXITCODE -ne 0) {
        throw "takeown.exe failed with exit code $LASTEXITCODE."
    }

    & $icaclsPath @icaclsArguments
    if ($LASTEXITCODE -ne 0) {
        throw "icacls.exe failed with exit code $LASTEXITCODE."
    }
}
catch {
    $failure = $_
    Microsoft.PowerShell.Utility\Write-Host $_.Exception.Message -ForegroundColor Red
}

if ($Pause) {
    [void](Microsoft.PowerShell.Utility\Read-Host 'Press Enter to continue')
}
if ($null -ne $failure) {
    throw $failure
}
