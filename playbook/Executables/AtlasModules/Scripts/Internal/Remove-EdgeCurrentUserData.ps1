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

function Get-AtlasEdgeExecutablePaths {
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($folderName in @('ProgramFilesX86', 'ProgramFiles')) {
        $programFilesPath = [Environment]::GetFolderPath($folderName)
        if ([string]::IsNullOrWhiteSpace($programFilesPath)) {
            continue
        }

        $edgeExecutablePath = [IO.Path]::GetFullPath([IO.Path]::Combine(
                $programFilesPath,
                'Microsoft',
                'Edge',
                'Application',
                'msedge.exe'
            ))
        if (-not $paths.Contains($edgeExecutablePath)) {
            $paths.Add($edgeExecutablePath)
        }
    }

    return $paths.ToArray()
}

function Remove-AtlasOrphanedEdgeAutoLaunch {
    [CmdletBinding()]
    param(
        [string]$RunSubKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        [string[]]$StartupApprovedSubKeys = @(
            'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
            'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
        ),
        [string[]]$KnownEdgeExecutablePaths
    )

    if ($null -eq $KnownEdgeExecutablePaths -or $KnownEdgeExecutablePaths.Count -eq 0) {
        $KnownEdgeExecutablePaths = @(Get-AtlasEdgeExecutablePaths)
    }

    $canonicalEdgePaths = [Collections.Generic.List[string]]::new()
    foreach ($knownPath in @($KnownEdgeExecutablePaths)) {
        if ([string]::IsNullOrWhiteSpace($knownPath)) {
            continue
        }
        $canonicalPath = [IO.Path]::GetFullPath($knownPath)
        if (-not $canonicalEdgePaths.Contains($canonicalPath)) {
            $canonicalEdgePaths.Add($canonicalPath)
        }
    }
    if ($canonicalEdgePaths.Count -eq 0) {
        throw 'No canonical Microsoft Edge executable paths are available.'
    }

    $runValueNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $removedValueNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $runKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($RunSubKey, $true)
    if ($null -ne $runKey) {
        try {
            foreach ($valueName in @($runKey.GetValueNames())) {
                $null = $runValueNames.Add($valueName)
                if ($valueName -notmatch '^MicrosoftEdgeAutoLaunch_[0-9A-F]{32}$') {
                    continue
                }

                $valueKind = $runKey.GetValueKind($valueName)
                if ($valueKind -notin @(
                        [Microsoft.Win32.RegistryValueKind]::String,
                        [Microsoft.Win32.RegistryValueKind]::ExpandString
                    )) {
                    continue
                }

                $command = [string]$runKey.GetValue(
                    $valueName,
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                if ($valueKind -eq [Microsoft.Win32.RegistryValueKind]::ExpandString) {
                    $command = [Environment]::ExpandEnvironmentVariables($command)
                }

                $match = [regex]::Match(
                    $command,
                    '^\s*"(?<Executable>[^"]+)"\s+--no-startup-window\s+--win-session-start\s*$',
                    [Text.RegularExpressions.RegexOptions]::IgnoreCase
                )
                if (-not $match.Success) {
                    continue
                }

                try {
                    $commandExecutablePath = [IO.Path]::GetFullPath(
                        $match.Groups['Executable'].Value
                    )
                }
                catch {
                    continue
                }

                $isKnownEdgePath = $false
                foreach ($canonicalEdgePath in $canonicalEdgePaths) {
                    if ([string]::Equals(
                            $commandExecutablePath,
                            $canonicalEdgePath,
                            [StringComparison]::OrdinalIgnoreCase
                        )) {
                        $isKnownEdgePath = $true
                        break
                    }
                }
                if (-not $isKnownEdgePath -or [IO.File]::Exists($commandExecutablePath)) {
                    continue
                }

                $runKey.DeleteValue($valueName, $false)
                $null = $runValueNames.Remove($valueName)
                $null = $removedValueNames.Add($valueName)
            }
        }
        finally {
            $runKey.Dispose()
        }
    }

    foreach ($approvedSubKey in $StartupApprovedSubKeys) {
        $approvedKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
            $approvedSubKey,
            $true
        )
        if ($null -eq $approvedKey) {
            continue
        }

        try {
            foreach ($approvedValueName in @($approvedKey.GetValueNames())) {
                $isRemovedRunValue = $removedValueNames.Contains($approvedValueName)
                $isOrphanedEdgeValue = (
                    $approvedValueName -match '^MicrosoftEdgeAutoLaunch_[0-9A-F]{32}$' -and
                    -not $runValueNames.Contains($approvedValueName)
                )
                if (-not $isRemovedRunValue -and -not $isOrphanedEdgeValue) {
                    continue
                }

                $approvedKey.DeleteValue($approvedValueName, $false)
                $null = $removedValueNames.Add($approvedValueName)
            }
        }
        finally {
            $approvedKey.Dispose()
        }
    }

    return @($removedValueNames)
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

$removedAutoLaunchValues = @(Remove-AtlasOrphanedEdgeAutoLaunch)
foreach ($removedAutoLaunchValue in $removedAutoLaunchValues) {
    Write-Verbose "Removed orphaned Edge startup registration '$removedAutoLaunchValue'."
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
