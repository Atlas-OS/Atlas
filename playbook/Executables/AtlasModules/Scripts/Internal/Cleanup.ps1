$ErrorActionPreference = 'Stop'

$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$initScript = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    throw "Atlas PowerShell initialization script '$initScript' is missing."
}

. $initScript

function Invoke-AtlasDiskCleanup {
    Get-Process -Name cleanmgr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $regValues = @{
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

    foreach ($entry in $regValues.GetEnumerator()) {
        $key = Join-Path -Path $baseKey -ChildPath $entry.Key
        if (-not (Test-Path -LiteralPath $key)) {
            Write-Output "'$key' not found, not configuring it."
            continue
        }

        Set-ItemProperty -Path $key -Name 'StateFlags0064' -Value $entry.Value -Type DWord -ErrorAction Stop
    }

    Start-Process -FilePath 'cleanmgr.exe' -ArgumentList '/sagerun:64' | Out-Null
}

function Test-OtherWindowsInstall {
    $systemDrive = Get-SystemDrive
    $drives = (Get-PSDrive -PSProvider FileSystem).Root | Where-Object { $_ -ne $systemDrive }

    foreach ($drive in $drives) {
        if (Test-Path -LiteralPath (Join-Path -Path $drive -ChildPath 'Windows') -PathType Container) {
            return $true
        }
    }

    return $false
}

function Clear-DirectoryChildren {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$ExcludeName = @()
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Cleanup path '$Path' is not a directory."
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
    Get-ChildItem -LiteralPath $resolvedPath -Force -ErrorAction Stop |
        Where-Object { $ExcludeName -notcontains $_.Name } |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
        }
}

function Get-FirstExistingDirectory {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Container)) {
            return (Resolve-Path -LiteralPath $path).ProviderPath
        }
    }

    return $null
}

if (Test-OtherWindowsInstall) {
    Write-Output 'Not running Disk Cleanup, other Windows drives found.'
}
else {
    Write-Output 'No other Windows drives found, running Disk Cleanup.'
    Invoke-AtlasDiskCleanup
}

$localAppDataTemp = if ($env:LOCALAPPDATA) { Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Temp' } else { $null }
$userTemp = Get-FirstExistingDirectory -Paths @($env:TEMP, $env:TMP, $localAppDataTemp)
if ($userTemp) {
    Write-Output 'Cleaning user TEMP folder...'
    Clear-DirectoryChildren -Path $userTemp -ExcludeName @('AME')
}
else {
    Write-Error 'User temp folder not found!'
}

$machine = [System.EnvironmentVariableTarget]::Machine
$systemTemp = Get-FirstExistingDirectory -Paths @(
    [System.Environment]::GetEnvironmentVariable('Temp', $machine),
    [System.Environment]::GetEnvironmentVariable('Tmp', $machine),
    (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Temp')
)
if ($systemTemp) {
    Write-Output 'Cleaning system TEMP folder...'
    Clear-DirectoryChildren -Path $systemTemp
}
else {
    Write-Error 'System temp folder not found!'
}

$vssadminOutput = & vssadmin.exe delete shadows /all /quiet 2>&1
$vssadminExitCode = $LASTEXITCODE
if ($vssadminOutput) {
    $vssadminOutput | Write-Output
}

if ($vssadminExitCode -ne 0) {
    $noRestorePoints = $vssadminOutput -match 'No items found that satisfy the query'
    if ($noRestorePoints) {
        Write-Output 'No restore points found, skipping shadow copy deletion.'
        $global:LASTEXITCODE = 0
    }
    else {
        throw "vssadmin.exe failed to delete restore points with exit code $vssadminExitCode."
    }
}
