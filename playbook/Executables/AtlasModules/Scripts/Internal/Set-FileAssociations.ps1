[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Base', 'Microsoft Edge', 'Brave', 'LibreWolf', 'Firefox', 'Google Chrome')]
    [string] $AssociationProfile = 'Base',

    [Parameter()]
    [switch] $PlanOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Windows requires user interaction in system UI for default changes and adds
# extra protection around browser defaults. Microsoft documents the supported
# paths as Settings (ms-settings:defaultapps), managed-device
# DefaultAssociationsConfiguration policy, or DISM defaults applied at first
# sign-in. This script deliberately does not synthesize protected registry data.
# https://learn.microsoft.com/windows/apps/develop/windows-integration/default-apps-platform
# https://learn.microsoft.com/windows/win32/shell/how-to-include-an-application-on-the-open-with-dialog-box

function Assert-IntendedInteractiveUser {
    [CmdletBinding()]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = $identity.User.Value
    $serviceSid = $sid -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20') -or $sid -like 'S-1-5-80-*'
    if ($serviceSid) {
        throw "File associations must run as the intended signed-in user, not service identity '$sid'."
    }

    if (-not [Environment]::UserInteractive -or [Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0) {
        throw 'File associations must run in the intended user interactive session.'
    }

    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'File associations must run as the intended non-elevated user.'
    }
}

function Test-MachineClassRegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProgId
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Classes\$ProgId", $false)
    try {
        return $null -ne $key
    }
    finally {
        if ($null -ne $key) {
            $key.Close()
        }
    }
}

function New-RegistryValuePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [object] $Value,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryValueKind] $Kind
    )

    [pscustomobject]@{
        Hive  = 'CurrentUser'
        Path  = $Path
        Name  = $Name
        Value = $Value
        Kind  = $Kind
    }
}

function Get-MissingCurrentUserKeyPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $missingPaths = @()
    $candidate = $Path
    while (-not [string]::IsNullOrEmpty($candidate)) {
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($candidate, $false)
        if ($null -ne $key) {
            $key.Close()
            break
        }

        $missingPaths += $candidate
        $separatorIndex = $candidate.LastIndexOf('\')
        if ($separatorIndex -lt 0) {
            break
        }
        $candidate = $candidate.Substring(0, $separatorIndex)
    }

    $missingPaths
}

function Get-RegistryValueSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Change
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Change.Path, $false)
    $missingPaths = if ($null -eq $key) {
        @(Get-MissingCurrentUserKeyPath -Path $Change.Path)
    }
    else {
        @()
    }
    try {
        $keyExisted = $null -ne $key
        $valueExisted = $false
        $value = $null
        $kind = $null

        if ($keyExisted -and $Change.Name -in $key.GetValueNames()) {
            $valueExisted = $true
            $value = $key.GetValue(
                $Change.Name,
                $null,
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
            )
            $kind = $key.GetValueKind($Change.Name)
        }

        [pscustomobject]@{
            Path         = $Change.Path
            Name         = $Change.Name
            KeyExisted   = $keyExisted
            ValueExisted = $valueExisted
            Value        = $value
            Kind         = $kind
            MissingPaths = $missingPaths
        }
    }
    finally {
        if ($null -ne $key) {
            $key.Close()
        }
    }
}

function Set-CurrentUserRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Change
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($Change.Path)
    if ($null -eq $key) {
        throw "Unable to open current-user registry key '$($Change.Path)' for writing."
    }

    try {
        $key.SetValue($Change.Name, $Change.Value, $Change.Kind)
    }
    finally {
        $key.Close()
    }
}

function Remove-CurrentUserKeyIfEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Path, $true)
    if ($null -eq $key) {
        return
    }

    try {
        $isEmpty = $key.GetSubKeyNames().Count -eq 0 -and $key.GetValueNames().Count -eq 0
    }
    finally {
        $key.Close()
    }

    if ($isEmpty) {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKey($Path, $false)
    }
}

function Restore-CurrentUserRegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Snapshot
    )

    if ($Snapshot.ValueExisted) {
        $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($Snapshot.Path)
        if ($null -eq $key) {
            throw "Unable to reopen current-user registry key '$($Snapshot.Path)' during rollback."
        }

        try {
            $key.SetValue($Snapshot.Name, $Snapshot.Value, $Snapshot.Kind)
        }
        finally {
            $key.Close()
        }
        return
    }

    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($Snapshot.Path, $true)
    if ($null -ne $key) {
        try {
            $key.DeleteValue($Snapshot.Name, $false)
        }
        finally {
            $key.Close()
        }
    }

    foreach ($missingPath in $Snapshot.MissingPaths) {
        Remove-CurrentUserKeyIfEmpty -Path $missingPath
    }
}

$archiveExtensions = @(
    '001', '7z', 'apfs', 'arj', 'bz2', 'bzip2', 'cab', 'cpio', 'deb', 'dmg',
    'esd', 'fat', 'gz', 'gzip', 'hfs', 'iso', 'lha', 'lzh', 'lzma', 'ntfs',
    'rar', 'rpm', 'squashfs', 'swm', 'tar', 'taz', 'tbz', 'tbz2', 'tgz',
    'tpz', 'txz', 'vhd', 'vhdx', 'wim', 'xar', 'xz', 'z', 'zip'
)

$changes = New-Object 'System.Collections.Generic.List[object]'
$registeredArchiveCount = 0
foreach ($extension in $archiveExtensions) {
    $progId = "7-Zip.$extension"
    if (-not (Test-MachineClassRegistration -ProgId $progId)) {
        continue
    }

    $registeredArchiveCount++
    $changes.Add((New-RegistryValuePlan `
        -Path "SOFTWARE\Classes\.$extension\OpenWithProgids" `
        -Name $progId `
        -Value '' `
        -Kind ([Microsoft.Win32.RegistryValueKind]::String)))
}

if ($registeredArchiveCount -gt 0) {
    $changes.Add((New-RegistryValuePlan `
        -Path 'SOFTWARE\7-Zip\Options' `
        -Name 'ContextMenu' `
        -Value 1073746726 `
        -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)))
}

$browserDefaultRequested = $AssociationProfile -ne 'Base'
$result = [pscustomobject]@{
    Profile                    = $AssociationProfile
    Mode                       = if ($PlanOnly) { 'PlanOnly' } else { 'Apply' }
    BrowserDefaultRequested    = $browserDefaultRequested
    BrowserDefaultDisposition  = if ($browserDefaultRequested) { 'WindowsProtectedUserActionRequired' } else { 'NotRequested' }
    DefaultAppsSettingsUri     = 'ms-settings:defaultapps'
    ManagedDevicePolicy        = 'DefaultAssociationsConfiguration'
    FirstSignInProvisioning    = 'Import-DefaultAppAssociations'
    HandlerRegistration        = 'OpenWithProgidsOnly'
    Rollback                   = 'ExactValueSnapshotOnError'
    Changes                    = $changes.ToArray()
}

if ($PlanOnly) {
    $result
    return
}

Assert-IntendedInteractiveUser

if ($browserDefaultRequested) {
    Write-Warning "The '$AssociationProfile' browser default remains user-controlled. Open ms-settings:defaultapps, or use documented managed-device/first-sign-in provisioning."
}

$snapshots = New-Object 'System.Collections.Generic.List[object]'
try {
    foreach ($change in $changes) {
        $snapshots.Add((Get-RegistryValueSnapshot -Change $change))
        Set-CurrentUserRegistryValue -Change $change
    }
}
catch {
    $applyError = $_
    $rollbackErrors = New-Object 'System.Collections.Generic.List[string]'

    for ($index = $snapshots.Count - 1; $index -ge 0; $index--) {
        try {
            Restore-CurrentUserRegistryValue -Snapshot $snapshots[$index]
        }
        catch {
            $rollbackErrors.Add($_.Exception.Message)
        }
    }

    if ($rollbackErrors.Count -gt 0) {
        throw "File-association update failed: $($applyError.Exception.Message) Rollback also failed: $($rollbackErrors -join '; ')"
    }
    throw $applyError
}

$result
