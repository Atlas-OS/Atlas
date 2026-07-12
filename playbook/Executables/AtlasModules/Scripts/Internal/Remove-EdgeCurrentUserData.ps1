<#
.SYNOPSIS
    Removes Edge registrations and data for the exact install-state interactive user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid
)

$trustBootstrap = [IO.Path]::Combine($PSScriptRoot, 'Initialize-PowerShellTrust.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Assert-AtlasUserPathBoundary {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RequireTarget
    )

    $canonicalRoot = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $canonicalPath = [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $rootPrefix = $canonicalRoot + [IO.Path]::DirectorySeparatorChar
    if ([string]$canonicalPath -cne [string]$canonicalRoot -and
        -not $canonicalPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "User cleanup path '$canonicalPath' escaped exact-user root '$canonicalRoot'."
    }
    if (-not [IO.Directory]::Exists($canonicalRoot)) {
        throw "Exact-user cleanup root '$canonicalRoot' is unavailable."
    }

    $cursor = $canonicalRoot
    $relative = $canonicalPath.Substring($canonicalRoot.Length).TrimStart(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $components = @($canonicalRoot)
    if (-not [string]::IsNullOrWhiteSpace($relative)) {
        foreach ($component in $relative.Split(@(
                    [IO.Path]::DirectorySeparatorChar,
                    [IO.Path]::AltDirectorySeparatorChar
                ), [StringSplitOptions]::RemoveEmptyEntries)) {
            $cursor = [IO.Path]::Combine($cursor, $component)
            $components += $cursor
        }
    }

    foreach ($componentPath in $components) {
        if (-not [IO.Directory]::Exists($componentPath)) {
            if ($RequireTarget) {
                throw "Exact-user cleanup path component '$componentPath' is unavailable."
            }
            break
        }
        $attributes = [IO.File]::GetAttributes($componentPath)
        if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Exact-user cleanup path component '$componentPath' is a reparse point."
        }
    }

    return $canonicalPath
}

function Remove-AtlasUserFileSystemEntry {
    param(
        [Parameter(Mandatory = $true)]
        [IO.FileSystemInfo]$Entry
    )

    $attributes = [IO.File]::GetAttributes($Entry.FullName)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        if ($Entry.PSIsContainer) {
            [IO.Directory]::Delete($Entry.FullName, $false)
        }
        else {
            [IO.File]::Delete($Entry.FullName)
        }
        return
    }

    if ($Entry.PSIsContainer) {
        foreach ($child in @(Microsoft.PowerShell.Management\Get-ChildItem `
                    -LiteralPath $Entry.FullName -Force -ErrorAction Stop)) {
            Remove-AtlasUserFileSystemEntry -Entry $child
        }
        [IO.File]::SetAttributes($Entry.FullName, [IO.FileAttributes]::Normal)
        [IO.Directory]::Delete($Entry.FullName, $false)
        return
    }

    [IO.File]::SetAttributes($Entry.FullName, [IO.FileAttributes]::Normal)
    [IO.File]::Delete($Entry.FullName)
}

$expectedSid = try {
    (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value
}
catch {
    throw "The expected Edge-cleanup user SID '$ExpectedUserSid' is invalid."
}
$actualSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ([string]$actualSid -cne [string]$expectedSid) {
    throw "Edge-cleanup token SID '$actualSid' does not match install-state SID '$expectedSid'."
}

$rawLocalAppDataPath = [Environment]::GetFolderPath('LocalApplicationData')
$rawRoamingAppDataPath = [Environment]::GetFolderPath('ApplicationData')
$rawDesktopPath = [Environment]::GetFolderPath('DesktopDirectory')
if ([string]::IsNullOrWhiteSpace($rawLocalAppDataPath)) {
    throw 'The exact user LocalApplicationData path is unavailable.'
}

# Per-user known folders are redirectable. Bind each exact-token result as its own
# authority root instead of assuming it is lexically below UserProfile.
$localAppDataPath = [IO.Path]::GetFullPath($rawLocalAppDataPath)
$localAppDataPath = Assert-AtlasUserPathBoundary -Root $localAppDataPath `
    -Path $localAppDataPath -RequireTarget
$edgeDataPath = Assert-AtlasUserPathBoundary -Root $localAppDataPath `
    -Path ([IO.Path]::Combine($localAppDataPath, 'Microsoft', 'Edge'))

$shortcutDirectories = @()
if (-not [string]::IsNullOrWhiteSpace($rawRoamingAppDataPath) -and
    [IO.Directory]::Exists($rawRoamingAppDataPath)) {
    try {
        $roamingAppDataPath = [IO.Path]::GetFullPath($rawRoamingAppDataPath)
        $roamingAppDataPath = Assert-AtlasUserPathBoundary -Root $roamingAppDataPath `
            -Path $roamingAppDataPath -RequireTarget
        $shortcutDirectories += @(
            (Assert-AtlasUserPathBoundary -Root $roamingAppDataPath -Path ([IO.Path]::Combine(
                        $roamingAppDataPath,
                        'Microsoft',
                        'Internet Explorer',
                        'Quick Launch'
                    )))
            (Assert-AtlasUserPathBoundary -Root $roamingAppDataPath -Path ([IO.Path]::Combine(
                        $roamingAppDataPath,
                        'Microsoft',
                        'Internet Explorer',
                        'Quick Launch',
                        'User Pinned',
                        'TaskBar'
                    )))
            (Assert-AtlasUserPathBoundary -Root $roamingAppDataPath -Path ([IO.Path]::Combine(
                        $roamingAppDataPath,
                        'Microsoft',
                        'Windows',
                        'Start Menu',
                        'Programs'
                    )))
        )
    }
    catch {
        Write-Warning "Skipping redirected roaming shortcut cleanup: $($_.Exception.Message)"
    }
}
if (-not [string]::IsNullOrWhiteSpace($rawDesktopPath) -and
    [IO.Directory]::Exists($rawDesktopPath)) {
    try {
        $desktopPath = [IO.Path]::GetFullPath($rawDesktopPath)
        $shortcutDirectories += Assert-AtlasUserPathBoundary -Root $desktopPath `
            -Path $desktopPath -RequireTarget
    }
    catch {
        Write-Warning "Skipping redirected Desktop shortcut cleanup: $($_.Exception.Message)"
    }
}

# All identity, containment and reparse validation above must complete before the first
# registry or filesystem mutation below.
foreach ($registryPath in @(
        'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge'
        'HKCU:\SOFTWARE\Classes\microsoft-edge'
        'HKCU:\SOFTWARE\Classes\MSEdgeHTM'
    )) {
    if (Microsoft.PowerShell.Management\Test-Path -LiteralPath $registryPath) {
        Microsoft.PowerShell.Management\Remove-Item -LiteralPath $registryPath -Recurse -Force
    }
}

if ([IO.Directory]::Exists($edgeDataPath)) {
    $edgeEntry = Microsoft.PowerShell.Management\Get-Item -LiteralPath $edgeDataPath -Force
    Remove-AtlasUserFileSystemEntry -Entry $edgeEntry
}

foreach ($shortcutDirectory in @($shortcutDirectories | Select-Object -Unique)) {
    if (-not [IO.Directory]::Exists($shortcutDirectory)) {
        continue
    }
    foreach ($shortcutName in @('edge.lnk', 'Microsoft Edge.lnk')) {
        $shortcutPath = [IO.Path]::Combine($shortcutDirectory, $shortcutName)
        if ([IO.File]::Exists($shortcutPath)) {
            [IO.File]::SetAttributes($shortcutPath, [IO.FileAttributes]::Normal)
            [IO.File]::Delete($shortcutPath)
        }
    }
}
