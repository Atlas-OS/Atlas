<#
.SYNOPSIS
    Removes OneDrive registrations and safe leftovers for the exact install-state user.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedUserSid,
    [switch]$DeferFileCleanup,
    [ValidateRange(0, [long]::MaxValue)]
    [long]$AfterBootUtcTicks = 0
)

$trustBootstrap = [IO.Path]::Combine([IO.Path]::GetDirectoryName($PSScriptRoot), 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($trustBootstrap)) {
    throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
}
. $trustBootstrap

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

try {
    $transcriptDirectory = Join-Path $env:LOCALAPPDATA 'AtlasOS\Logs'
    $null = New-Item -Path $transcriptDirectory -ItemType Directory -Force
    $transcriptName = '{0:yyyyMMdd-HHmmss}-onedrive-cleanup-{1}.log' -f (Get-Date), $PID
    Start-Transcript -Path (Join-Path $transcriptDirectory $transcriptName) | Out-Null
}
catch {
    # Diagnostics must not prevent optional leftover cleanup.
    $null = $_
}

function ConvertTo-AtlasOneDriveUserSid {
    param([Parameter(Mandatory = $true)][string]$Sid)

    try {
        $canonicalSid = (New-Object Security.Principal.SecurityIdentifier($Sid)).Value
    }
    catch {
        throw "The expected OneDrive-cleanup user SID '$Sid' is invalid."
    }
    if ($canonicalSid -notmatch '^S-1-5-21-(?:\d+-){2}\d+-\d+$') {
        throw "The expected OneDrive-cleanup SID '$canonicalSid' is not a local or domain account SID."
    }
    return $canonicalSid
}

function Resolve-AtlasOneDriveUserDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($Root)) {
        throw "The exact-user OneDrive cleanup root for '$ChildPath' is unavailable."
    }
    $canonicalRoot = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    if (-not [IO.Directory]::Exists($canonicalRoot)) {
        throw "The exact-user OneDrive cleanup root '$canonicalRoot' is unavailable."
    }
    if (([IO.File]::GetAttributes($canonicalRoot) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "The exact-user OneDrive cleanup root '$canonicalRoot' is a reparse point."
    }

    $target = [IO.Path]::GetFullPath([IO.Path]::Combine($canonicalRoot, $ChildPath))
    $prefix = $canonicalRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "OneDrive cleanup path '$target' escaped exact-user root '$canonicalRoot'."
    }

    $cursor = $canonicalRoot
    $relative = $target.Substring($canonicalRoot.Length).TrimStart(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    foreach ($component in $relative.Split(@(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ), [StringSplitOptions]::RemoveEmptyEntries)) {
        $cursor = [IO.Path]::Combine($cursor, $component)
        if (-not [IO.Directory]::Exists($cursor)) {
            break
        }
        if (([IO.File]::GetAttributes($cursor) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "OneDrive cleanup path component '$cursor' is a reparse point."
        }
    }
    return $target
}

function Remove-AtlasOneDriveUserEntry {
    param(
        [Parameter(Mandatory = $true)][IO.FileSystemInfo]$Entry,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Failures
    )

    try {
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
            $failuresBefore = $Failures.Count
            foreach ($child in @(Microsoft.PowerShell.Management\Get-ChildItem `
                        -LiteralPath $Entry.FullName -Force -ErrorAction Stop)) {
                Remove-AtlasOneDriveUserEntry -Entry $child -Failures $Failures
            }
            # Leave the parent of a retained file; avoid reporting the same failure
            # again as a nonempty-directory error at each ancestor.
            if ($Failures.Count -gt $failuresBefore) { return }
            [IO.File]::SetAttributes($Entry.FullName, [IO.FileAttributes]::Normal)
            [IO.Directory]::Delete($Entry.FullName, $false)
            return
        }
        [IO.File]::SetAttributes($Entry.FullName, [IO.FileAttributes]::Normal)
        [IO.File]::Delete($Entry.FullName)
    }
    catch {
        $Failures.Add("$($Entry.FullName): $($_.Exception.Message)")
    }
}

function Remove-AtlasOneDriveUserTree {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyCollection()][System.Collections.Generic.List[string]]$Failures =
            (New-Object 'System.Collections.Generic.List[string]')
    )

    if ([IO.Directory]::Exists($Path)) {
        Remove-AtlasOneDriveUserEntry -Entry (
            Microsoft.PowerShell.Management\Get-Item -LiteralPath $Path -Force
        ) -Failures $Failures
    }
    if (-not $PSBoundParameters.ContainsKey('Failures') -and $Failures.Count -gt 0) {
        throw "OneDrive cleanup retained $($Failures.Count) item(s): $($Failures -join '; ')"
    }
}

function Get-AtlasOneDriveBootUtcTicks {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime `
            -ErrorAction Stop).LastBootUpTime
    if ($bootTime -isnot [datetime]) {
        throw 'Windows did not return a valid last boot time for deferred OneDrive cleanup.'
    }
    return $bootTime.ToUniversalTime().Ticks
}

function Register-AtlasOneDrivePostBootCleanup {
    param(
        [Parameter(Mandatory = $true)][string]$UserSid,
        [Parameter(Mandatory = $true)][long]$BootUtcTicks
    )

    $canonicalSid = ConvertTo-AtlasOneDriveUserSid -Sid $UserSid
    $windowsDirectory = [Environment]::GetFolderPath('Windows')
    $hiddenLauncher = Join-Path $windowsDirectory `
        'AtlasModules\Scripts\Entry\Invoke-OneDriveCleanupHidden.vbs'
    if (-not [IO.File]::Exists($hiddenLauncher)) {
        throw "The deferred OneDrive cleanup launcher is missing at '$hiddenLauncher'."
    }
    $command = '"{0}\System32\wscript.exe" "{1}" {2} {3}' -f `
        $windowsDirectory, $hiddenLauncher, $canonicalSid, $BootUtcTicks
    if ($command.Length -gt 260) {
        throw 'The deferred OneDrive cleanup command exceeds the Windows startup command limit.'
    }
    $runPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    # Recreating an existing registry key with -Force erases every startup value.
    if (-not (Test-Path -LiteralPath $runPath)) {
        $null = New-Item -Path $runPath -Force
    }
    New-ItemProperty -LiteralPath $runPath -Name AtlasOneDriveCleanup `
        -Value $command -PropertyType String -Force | Out-Null
}

$expectedSid = ConvertTo-AtlasOneDriveUserSid -Sid $ExpectedUserSid
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$actualSid = [string]$identity.User.Value
if ([string]$actualSid -cne [string]$expectedSid) {
    throw "OneDrive-cleanup token SID '$actualSid' does not match install-state SID '$expectedSid'."
}
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'OneDrive current-user cleanup refuses to run from an elevated token.'
}
if ([Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0) {
    throw 'OneDrive current-user cleanup requires an interactive user session.'
}
if ($DeferFileCleanup -and $AfterBootUtcTicks -ne 0) {
    throw 'Deferred registration and post-boot cleanup cannot run together.'
}
if ($AfterBootUtcTicks -ne 0) {
    # Explorer can process startup entries again when Atlas refreshes the shell.
    # Keep this transient entry until an actual reboot releases all installer DLLs.
    if ((Get-AtlasOneDriveBootUtcTicks) -le $AfterBootUtcTicks) {
        Write-Output 'OneDrive file cleanup is waiting for the installation reboot.'
        return
    }
    # Consume the entry before the one post-boot attempt; a failure remains in the
    # transcript instead of creating an unbounded task on every future logon.
    Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' `
        -Name AtlasOneDriveCleanup -ErrorAction Stop
}

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$roamingAppData = [Environment]::GetFolderPath('ApplicationData')
$userProfile = [Environment]::GetFolderPath('UserProfile')
$oneDriveCache = Resolve-AtlasOneDriveUserDirectory -Root $localAppData `
    -ChildPath 'Microsoft\OneDrive'
$oneDriveShortcut = Resolve-AtlasOneDriveUserDirectory -Root $roamingAppData `
    -ChildPath 'Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
$oneDriveFolder = Resolve-AtlasOneDriveUserDirectory -Root $userProfile -ChildPath 'OneDrive'

# Complete every identity and path-boundary check before the first mutation.
$processModule = Join-Path (Split-Path -Parent $PSScriptRoot) 'Modules\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
Import-Module -Name $processModule -ErrorAction Stop
$sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
# First-logon setup can still be installing OneDrive when RunOnce starts. Stop
# that producer before its children, then remove registrations it may have written.
# This script is already bound to the exact non-elevated user and session; never
# stop another session's client or invoke a user-writable uninstaller as SYSTEM.
Stop-AtlasProcess -Name 'OneDriveSetup' -SessionId $sessionId `
    -StopOnError -WaitTimeoutMilliseconds 5000
Stop-AtlasProcessUnderRoot -RootsLower @($oneDriveCache) -SessionId $sessionId
Microsoft.PowerShell.Management\Remove-ItemProperty `
    -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' `
    -Name 'OneDrive', 'OneDriveSetup' -Force -ErrorAction SilentlyContinue

foreach ($parent in @(
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
    foreach ($key in @(Microsoft.PowerShell.Management\Get-ChildItem `
                -LiteralPath $parent -ErrorAction SilentlyContinue)) {
        if ($key.PSChildName -like '*OneDrive*') {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $key.PSPath `
                -Recurse -Force -ErrorAction Stop
        }
    }
}

foreach ($registryPath in @(
        'HKCU:\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKCU:\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKCU:\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
        'HKCU:\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
    )) {
    Microsoft.PowerShell.Management\Remove-Item -LiteralPath $registryPath `
        -Recurse -Force -ErrorAction SilentlyContinue
}
Microsoft.PowerShell.Management\Remove-ItemProperty -LiteralPath 'HKCU:\Environment' `
    -Name 'OneDrive' -Force -ErrorAction SilentlyContinue

$shellFolders = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$shellFolderKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
    'Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders',
    $false
)
if ($null -ne $shellFolderKey) {
    try {
        foreach ($entry in @(
                @{ Name = '{F42EE2D3-909F-4907-8871-4C22FC0BF756}'; Data = '%USERPROFILE%\Documents' }
                @{ Name = 'Personal'; Data = '%USERPROFILE%\Documents' }
                @{ Name = 'Desktop'; Data = '%USERPROFILE%\Desktop' }
                @{ Name = 'My Pictures'; Data = '%USERPROFILE%\Pictures' }
                @{ Name = '{0DDD015D-B06C-45D5-8C4C-F59713854639}'; Data = '%USERPROFILE%\Pictures' }
            )) {
            $currentValue = [string]$shellFolderKey.GetValue(
                $entry.Name,
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            if ($currentValue -match '(?i)(?:^|[\\/])OneDrive(?:[\\/]|$)') {
                Microsoft.PowerShell.Management\New-ItemProperty -LiteralPath $shellFolders `
                    -Name $entry.Name -Value $entry.Data -PropertyType ExpandString `
                    -Force | Out-Null
            }
        }
    }
    finally {
        $shellFolderKey.Dispose()
    }
}

# Any process that used the shell, including an installer file picker, can retain
# OneDrive's DLL. Complete this exact-user file cleanup after the planned reboot.
if ($DeferFileCleanup) {
    Register-AtlasOneDrivePostBootCleanup -UserSid $expectedSid `
        -BootUtcTicks (Get-AtlasOneDriveBootUtcTicks)
    Write-Output 'OneDrive file cleanup scheduled for this user after the installation reboot.'
    return
}

$cleanupFailures = New-Object 'System.Collections.Generic.List[string]'
Remove-AtlasOneDriveUserTree -Path $oneDriveCache -Failures $cleanupFailures
if ([IO.File]::Exists($oneDriveShortcut)) {
    Remove-AtlasOneDriveUserEntry -Entry (
        Microsoft.PowerShell.Management\Get-Item -LiteralPath $oneDriveShortcut -Force
    ) -Failures $cleanupFailures
}

# The sync root can contain unsynced user data. Remove it only when no real files remain.
if ([IO.Directory]::Exists($oneDriveFolder)) {
    $remainingFiles = @(
        Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $oneDriveFolder `
            -Recurse -File -Force -ErrorAction Stop |
            Where-Object { $_.Name -cne 'desktop.ini' }
    )
    if ($remainingFiles.Count -eq 0) {
        Remove-AtlasOneDriveUserTree -Path $oneDriveFolder -Failures $cleanupFailures
    }
    else {
        Write-Warning "Not deleting '$oneDriveFolder': it still contains $($remainingFiles.Count) file(s)."
    }
}
if ($cleanupFailures.Count -gt 0) {
    throw "OneDrive cleanup retained $($cleanupFailures.Count) item(s): $($cleanupFailures -join '; ')"
}
Write-Output 'OneDrive current-user cleanup completed.'
