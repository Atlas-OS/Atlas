[CmdletBinding()]
param(
    [ValidateSet('Base', 'Microsoft Edge', 'Brave', 'LibreWolf', 'Firefox', 'Google Chrome')]
    [string] $AssociationProfile = 'Base',

    [string] $ExpectedUserSid,

    [switch] $PlanOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Windows protects browser defaults. Atlas only advertises installed archive
# handlers here; browser defaults remain owned by Settings or managed policy.

function Assert-IntendedInteractiveUser {
    [CmdletBinding()]
    param([string] $ExpectedUserSid)

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $sid = $identity.User.Value
        if ($ExpectedUserSid) {
            try {
                $expectedSid = (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value
            }
            catch {
                throw "The expected file-association user SID '$ExpectedUserSid' is invalid."
            }

            if ($sid -ne $expectedSid) {
                throw "File-association token SID '$sid' does not match expected SID '$expectedSid'."
            }
        }

        if ($sid -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20') -or $sid -like 'S-1-5-80-*') {
            throw "File associations must not run as service identity '$sid'."
        }
        if (-not [Environment]::UserInteractive -or [Diagnostics.Process]::GetCurrentProcess().SessionId -eq 0) {
            throw 'File associations must run in an interactive user session.'
        }

        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'File associations must run as a non-elevated user.'
        }
    }
    finally {
        $identity.Dispose()
    }
}

function Test-MachineClassRegistration {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $ProgId)

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Classes\$ProgId", $false)
    try {
        $null -ne $key
    }
    finally {
        if ($key) {
            $key.Dispose()
        }
    }
}

function New-AssociationChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Name,
        [Parameter(Mandatory)][AllowEmptyString()][object] $Value,
        [Parameter(Mandatory)][Microsoft.Win32.RegistryValueKind] $Kind
    )

    [pscustomobject]@{
        Hive  = 'CurrentUser'
        Path  = $Path
        Name  = $Name
        Value = $Value
        Kind  = $Kind
    }
}

function Get-ArchiveAssociationChanges {
    [CmdletBinding()]
    param()

    $extensions = @(
        '001', '7z', 'apfs', 'arj', 'bz2', 'bzip2', 'cab', 'cpio', 'deb', 'dmg',
        'esd', 'fat', 'gz', 'gzip', 'hfs', 'iso', 'lha', 'lzh', 'lzma', 'ntfs',
        'rar', 'rpm', 'squashfs', 'swm', 'tar', 'taz', 'tbz', 'tbz2', 'tgz',
        'tpz', 'txz', 'vhd', 'vhdx', 'wim', 'xar', 'xz', 'z', 'zip'
    )

    $changes = New-Object 'System.Collections.Generic.List[object]'
    foreach ($extension in $extensions) {
        $progId = "7-Zip.$extension"
        if (Test-MachineClassRegistration -ProgId $progId) {
            $changes.Add((New-AssociationChange `
                -Path "SOFTWARE\Classes\.$extension\OpenWithProgids" `
                -Name $progId `
                -Value '' `
                -Kind ([Microsoft.Win32.RegistryValueKind]::String)))
        }
    }

    if ($changes.Count -gt 0) {
        $changes.Add((New-AssociationChange `
            -Path 'SOFTWARE\7-Zip\Options' `
            -Name 'ContextMenu' `
            -Value 1073746726 `
            -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)))
    }

    $changes.ToArray()
}

function Set-CurrentUserRegistryValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject] $Change)

    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($Change.Path)
    if (-not $key) {
        throw "Unable to open current-user registry key '$($Change.Path)' for writing."
    }

    try {
        $key.SetValue($Change.Name, $Change.Value, $Change.Kind)
    }
    finally {
        $key.Dispose()
    }
}

function Set-AssociationChanges {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]] $Changes)

    foreach ($change in $Changes) {
        Set-CurrentUserRegistryValue -Change $change
    }
}

$changes = @(Get-ArchiveAssociationChanges)
$browserDefaultRequested = $AssociationProfile -ne 'Base'
$result = [pscustomobject]@{
    Profile                   = $AssociationProfile
    Mode                      = if ($PlanOnly) { 'PlanOnly' } else { 'Apply' }
    BrowserDefaultRequested   = $browserDefaultRequested
    BrowserDefaultDisposition = if ($browserDefaultRequested) { 'WindowsProtectedUserActionRequired' } else { 'NotRequested' }
    DefaultAppsSettingsUri    = 'ms-settings:defaultapps'
    ManagedDevicePolicy       = 'DefaultAssociationsConfiguration'
    FirstSignInProvisioning   = 'Import-DefaultAppAssociations'
    HandlerRegistration       = 'OpenWithProgidsOnly'
    Recovery                  = 'RerunIdempotently'
    Changes                   = $changes
}

if ($PlanOnly) {
    $result
    return
}

Assert-IntendedInteractiveUser -ExpectedUserSid $ExpectedUserSid
if ($browserDefaultRequested) {
    Write-Warning "The '$AssociationProfile' browser default remains user-controlled. Open ms-settings:defaultapps or use documented provisioning policy."
}

Set-AssociationChanges -Changes $changes
$result
