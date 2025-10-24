.\AtlasModules\initPowerShell.ps1

function Remove-FileSystemItem {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Item
    )

    try {
        $attributeMask = [System.IO.FileAttributes]::ReadOnly -bor [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden
        $item.Attributes = $item.Attributes -band (-bnot $attributeMask)

        if ($item -is [System.IO.DirectoryInfo]) {
            $item.Delete($true)
        }
        else {
            $item.Delete()
        }
    }
    catch {
        if ($item -is [System.IO.DirectoryInfo]) {
            Remove-Item -LiteralPath $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
        else {
            Remove-Item -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

function Clear-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string[]]$ExcludeNames = @(),
        [switch]$IncludeHidden
    )

    try {
        $directory = [System.IO.DirectoryInfo]::new($Path)
    }
    catch {
        return
    }

    if (-not $directory.Exists) { return }

    $excludeSet = $null
    if ($ExcludeNames.Count -gt 0) {
        $excludeSet = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($name in $ExcludeNames) {
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            [void]$excludeSet.Add($name)
        }
    }

    foreach ($item in $directory.EnumerateFileSystemInfos()) {
        if ($excludeSet -and $excludeSet.Contains($item.Name)) { continue }

        $attributes = $item.Attributes
        if (-not $IncludeHidden -and (($attributes -band [System.IO.FileAttributes]::Hidden) -or ($attributes -band [System.IO.FileAttributes]::System))) {
            continue
        }

        Remove-FileSystemItem -Item $item
    }
}

function Get-ExistingDirectory {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        try {
            $resolved = [System.IO.Path]::GetFullPath($candidate)
        }
        catch {
            continue
        }

        if (Test-Path -LiteralPath $resolved -PathType Container) {
            return $resolved
        }
    }

    return $null
}

function Invoke-AtlasDiskCleanup {
    # Kill running cleanmgr instances, as they will prevent new cleanmgr from starting
    Get-Process -Name cleanmgr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    # Disk Cleanup preset
    # 2 = enabled
    # 0 = disabled
    $baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $regValues = @{
        "Active Setup Temp Folders"             = 2
        "BranchCache"                           = 2
        "D3D Shader Cache"                      = 0
        "Delivery Optimization Files"           = 2
        "Diagnostic Data Viewer database files" = 2
        "Downloaded Program Files"              = 2
        "Internet Cache Files"                  = 2
        "Language Pack"                         = 0
        "Old ChkDsk Files"                      = 2
        "Recycle Bin"                           = 0
        "RetailDemo Offline Content"            = 2
        "Setup Log Files"                       = 2
        "System error memory dump files"        = 2
        "System error minidump files"           = 2
        "Temporary Files"                       = 0
        "Thumbnail Cache"                       = 2
        "Update Cleanup"                        = 0
        "User file versions"                    = 2
        "Windows Error Reporting Files"         = 2
        "Windows Defender"                      = 2
        "Temporary Sync Files"                  = 2
        "Device Driver Packages"                = 2
    }

    $existingKeys = @()
    try {
        $existingKeys = Get-ChildItem -Path $baseKey -ErrorAction Stop | Select-Object -ExpandProperty PSChildName
    }
    catch {
        $existingKeys = @()
    }

    $keyLookup = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($keyName in $existingKeys) {
        [void]$keyLookup.Add($keyName)
    }

    foreach ($entry in $regValues.GetEnumerator()) {
        $childKey = Join-Path -Path $baseKey -ChildPath $entry.Key

        if (-not $keyLookup.Contains($entry.Key)) {
            Write-Output "'$childKey' not found, not configuring it."
            continue
        }

        $currentValue = $null
        try {
            $currentValue = Get-ItemPropertyValue -Path $childKey -Name 'StateFlags0064' -ErrorAction Stop
        }
        catch {
            $currentValue = $null
        }

        if ($currentValue -ne $entry.Value) {
            Set-ItemProperty -Path $childKey -Name 'StateFlags0064' -Value $entry.Value -Type DWORD
        }
    }

    # Run preset 64 (0-65535)
    # As cleanmgr has multiple processes, there's no point in making the window hidden as it won't apply
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64" 2>&1 | Out-Null
}

# Check for other installations of Windows
# If so, don't cleanup as it will also cleanup other drives, which will be slow, and we don't want to touch other data
$systemDrivePattern = [regex]::Escape($(Get-SystemDrive))
$noCleanmgr = $false
foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
    if ($drive.Root -match $systemDrivePattern) { continue }

    $candidate = Join-Path -Path $drive.Root -ChildPath 'Windows'
    if (Test-Path -LiteralPath $candidate -PathType Container) {
        Write-Output "Not running Disk Cleanup, other Windows drives found."
        $noCleanmgr = $true
        break
    }
}

if (!$noCleanmgr) {
    Write-Output "No other Windows drives found, running Disk Cleanup."
    Invoke-AtlasDiskCleanup
}

# Clear the user temp folder
$localAppDataTemp = if ($env:LOCALAPPDATA) { Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Temp' } else { $null }
$userTemp = Get-ExistingDirectory @($env:TEMP, $env:TMP, $localAppDataTemp)
if ($userTemp) {
    Write-Output "Cleaning user TEMP folder..."
    Clear-DirectoryContents -Path $userTemp -ExcludeNames 'AME'
}
else {
    Write-Error "User temp folder not found!"
}

# Clear the system temp folder
$machineTarget = [System.EnvironmentVariableTarget]::Machine
$systemTemp = Get-ExistingDirectory @(
    [System.Environment]::GetEnvironmentVariable("Temp", $machineTarget),
    [System.Environment]::GetEnvironmentVariable("Tmp", $machineTarget),
    (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Temp')
)
if ($systemTemp) {
    Write-Output "Cleaning system TEMP folder..."
    Clear-DirectoryContents -Path $systemTemp -IncludeHidden
}
else {
    Write-Error "System temp folder not found!"
}

# Delete all system restore points
# This is so that users can't attempt to revert from Atlas to stock with Restore Points
# It won't work, a full Windows reinstall is required ^
vssadmin delete shadows /all /quiet
