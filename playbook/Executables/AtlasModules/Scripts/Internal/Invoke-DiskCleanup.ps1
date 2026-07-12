[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Machine', 'CurrentUser')]
    [string]$Scope,

    [string]$ExpectedUserSid
)

$ErrorActionPreference = 'Stop'

function Invoke-AtlasCleanupEntryRemoval {
    param([Parameter(Mandatory = $true)][string]$Path)

    $attributes = [IO.File]::GetAttributes($Path)
    $isDirectory = ($attributes -band [IO.FileAttributes]::Directory) -ne 0

    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        # Delete only the link. Never enumerate or delete its target.
        if ($isDirectory) {
            [IO.Directory]::Delete($Path, $false)
        }
        else {
            [IO.File]::Delete($Path)
        }
        return
    }

    if ($isDirectory) {
        foreach ($child in @([IO.Directory]::GetFileSystemEntries($Path))) {
            Invoke-AtlasCleanupEntryRemoval -Path $child
        }
        [IO.File]::SetAttributes($Path, [IO.FileAttributes]::Normal)
        [IO.Directory]::Delete($Path, $false)
        return
    }

    [IO.File]::SetAttributes($Path, [IO.FileAttributes]::Normal)
    [IO.File]::Delete($Path)
}

function Invoke-AtlasTempCleanup {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [IO.Path]::IsPathRooted($Path) -or -not [IO.Directory]::Exists($Path)) {
        throw "Cleanup path '$Path' is not a rooted directory."
    }
    if (([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Cleanup path '$Path' is a reparse point."
    }

    foreach ($entry in @([IO.Directory]::GetFileSystemEntries($Path))) {
        if ([IO.Path]::GetFileName($entry) -ceq 'AME') {
            continue
        }
        try {
            Invoke-AtlasCleanupEntryRemoval -Path $entry
        }
        catch {
            Write-Warning "Could not remove TEMP entry '$entry': $($_.Exception.Message)"
        }
    }
}

function Test-AtlasOtherWindowsInstall {
    param([Parameter(Mandatory = $true)][string]$SystemRoot)

    $canonicalSystemRoot = [IO.Path]::GetFullPath($SystemRoot).TrimEnd('\', '/')
    foreach ($drive in @(Get-PSDrive -PSProvider FileSystem -ErrorAction Stop)) {
        $driveRoot = [IO.Path]::GetFullPath([string]$drive.Root).TrimEnd('\', '/')
        if ([string]::Equals(
                $driveRoot,
                $canonicalSystemRoot,
                [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        if ([IO.Directory]::Exists([IO.Path]::Combine($driveRoot, 'Windows'))) {
            return $true
        }
    }

    return $false
}

function Invoke-AtlasDiskCleanup {
    param([Parameter(Mandatory = $true)][string]$CleanMgrPath)

    Get-Process -Name cleanmgr -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    $baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $categories = @{
        'Active Setup Temp Folders'             = 2
        'BranchCache'                           = 2
        'D3D Shader Cache'                      = 0
        'Delivery Optimization Files'           = 2
        'Diagnostic Data Viewer database files' = 2
        'Downloaded Program Files'              = 2
        'Internet Cache Files'                  = 2
        'Language Pack'                         = 0
        'Old ChkDsk Files'                      = 2
        'Recycle Bin'                           = 0
        'RetailDemo Offline Content'            = 2
        'Setup Log Files'                       = 2
        'System error memory dump files'        = 2
        'System error minidump files'           = 2
        'Temporary Files'                       = 0
        'Thumbnail Cache'                       = 2
        'Update Cleanup'                        = 0
        'User file versions'                    = 2
        'Windows Error Reporting Files'         = 2
        'Windows Defender'                      = 2
        'Temporary Sync Files'                  = 2
        'Device Driver Packages'                = 2
    }

    foreach ($category in $categories.GetEnumerator()) {
        $key = Join-Path -Path $baseKey -ChildPath $category.Key
        if (-not (Test-Path -LiteralPath $key)) {
            Write-Output "'$key' not found, not configuring it."
            continue
        }
        Set-ItemProperty -LiteralPath $key -Name 'StateFlags0064' `
            -Value $category.Value -Type DWord -ErrorAction Stop
    }

    Start-Process -FilePath $CleanMgrPath -ArgumentList '/sagerun:64' `
        -WindowStyle Hidden | Out-Null
}

function Invoke-AtlasSystemShadowCopyCleanup {
    param(
        [Parameter(Mandatory = $true)][string]$VssAdminPath,
        [Parameter(Mandatory = $true)][string]$SystemDrive
    )

    try {
        $volumes = @(Get-CimInstance -ClassName Win32_Volume `
                -Filter ("DriveLetter = '{0}'" -f $SystemDrive) -ErrorAction Stop)
        if ($volumes.Count -ne 1) {
            throw "Resolved $($volumes.Count) system volumes for '$SystemDrive'."
        }
        $volume = $volumes[0]
        $shadowCopies = @(Get-CimInstance -ClassName Win32_ShadowCopy -ErrorAction Stop |
            Where-Object { $_.VolumeName -eq $volume.DeviceID })
    }
    catch {
        Write-Warning "Could not inspect system-volume shadow copies: $($_.Exception.Message)"
        return
    }

    if ($shadowCopies.Count -eq 0) {
        Write-Output 'No restore points found, skipping shadow copy deletion.'
        return
    }

    $output = & $VssAdminPath delete shadows "/for=$SystemDrive" /all /quiet 2>&1
    $exitCode = $LASTEXITCODE
    if ($output) {
        $output | Write-Output
    }
    if ($exitCode -ne 0) {
        throw "vssadmin.exe failed to delete system-volume restore points with exit code $exitCode."
    }
}

function Invoke-AtlasMachineCleanup {
    param(
        [Parameter(Mandatory = $true)][string]$SystemRoot,
        [Parameter(Mandatory = $true)][string]$WindowsRoot,
        [Parameter(Mandatory = $true)][string]$CleanMgrPath,
        [Parameter(Mandatory = $true)][string]$VssAdminPath
    )

    if (Test-AtlasOtherWindowsInstall -SystemRoot $SystemRoot) {
        Write-Output 'Not running machine cleanup because another Windows installation was found.'
        return
    }

    foreach ($requiredExecutable in @($CleanMgrPath, $VssAdminPath)) {
        if (-not [IO.File]::Exists($requiredExecutable)) {
            throw "Required inbox cleanup executable '$requiredExecutable' is missing."
        }
    }
    if (-not [IO.Directory]::Exists($WindowsRoot) -or
        ([IO.File]::GetAttributes($WindowsRoot) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The exact Windows directory '$WindowsRoot' is unavailable or is a reparse point."
    }

    $systemDrive = [IO.Path]::GetFullPath($SystemRoot).TrimEnd('\', '/')
    Write-Output 'No other Windows installation found, running machine cleanup.'
    Invoke-AtlasDiskCleanup -CleanMgrPath $CleanMgrPath
    Invoke-AtlasTempCleanup -Path ([IO.Path]::Combine($WindowsRoot, 'Temp'))
    Invoke-AtlasSystemShadowCopyCleanup -VssAdminPath $VssAdminPath -SystemDrive $systemDrive
}

if ($Scope -eq 'CurrentUser') {
    if ([string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
        throw 'Current-user TEMP cleanup requires the install-state user SID.'
    }
    $expectedSid = try {
        (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value
    }
    catch {
        throw "The expected TEMP-cleanup user SID '$ExpectedUserSid' is invalid."
    }
    $actualSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if ([string]$actualSid -cne [string]$expectedSid) {
        throw "TEMP-cleanup token SID '$actualSid' does not match install-state SID '$expectedSid'."
    }

    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData) -or
        -not [IO.Path]::IsPathRooted($localAppData) -or
        -not [IO.Directory]::Exists($localAppData)) {
        throw 'The exact user LocalApplicationData directory is unavailable for TEMP cleanup.'
    }
    $localAppData = [IO.Path]::GetFullPath($localAppData)
    if (([IO.File]::GetAttributes($localAppData) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The exact user LocalApplicationData directory '$localAppData' is a reparse point."
    }

    Write-Output 'Cleaning install-state user TEMP folder...'
    Invoke-AtlasTempCleanup -Path ([IO.Path]::Combine($localAppData, 'Temp'))
    return
}

if (-not [string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
    throw 'Machine disk cleanup must not accept a user SID.'
}

$scriptsRoot = Split-Path -Parent $PSScriptRoot
$coreManifest = Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1'
Import-Module -Name $coreManifest -Force -ErrorAction Stop
Assert-AtlasPrivilege -TrustedInstaller

$systemRoot = [IO.Path]::GetPathRoot([Environment]::SystemDirectory)
$windowsRoot = [IO.Directory]::GetParent([Environment]::SystemDirectory).FullName
$cleanMgrPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'cleanmgr.exe')
$vssAdminPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'vssadmin.exe')
Invoke-AtlasMachineCleanup -SystemRoot $systemRoot -WindowsRoot $windowsRoot `
    -CleanMgrPath $cleanMgrPath -VssAdminPath $vssAdminPath
