# Atlas.Shell domain: current-user file associations.
#
# Windows protects browser defaults. Atlas only advertises installed archive handlers
# here; browser defaults remain owned by Settings or managed policy.

function Assert-AtlasFileAssociationUser {
    <#
    .SYNOPSIS
        Verifies that the current token is the intended interactive, non-elevated user.
    #>
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$ExpectedUserSid
    )

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

function Test-AtlasMachineClassRegistration {
    <#
    .SYNOPSIS
        Reports whether a ProgId is registered under the machine's HKLM\SOFTWARE\Classes.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProgId
    )

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Classes\$ProgId", $false)
    try {
        return ($null -ne $key)
    }
    finally {
        if ($key) {
            $key.Dispose()
        }
    }
}

function New-AtlasFileAssociationChange {
    <#
    .SYNOPSIS
        Describes one current-user registry value that a file-association plan writes.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [object]$Value,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryValueKind]$Kind
    )

    return [pscustomobject]@{
        Hive  = 'CurrentUser'
        Path  = $Path
        Name  = $Name
        Value = $Value
        Kind  = $Kind
    }
}

function Get-AtlasArchiveAssociationChange {
    <#
    .SYNOPSIS
        Builds the OpenWithProgids advertisements for every 7-Zip archive handler the
        machine has registered, plus the 7-Zip context-menu option when any exists.
    #>
    $extensions = @(
        '001', '7z', 'apfs', 'arj', 'bz2', 'bzip2', 'cab', 'cpio', 'deb', 'dmg',
        'esd', 'fat', 'gz', 'gzip', 'hfs', 'iso', 'lha', 'lzh', 'lzma', 'ntfs',
        'rar', 'rpm', 'squashfs', 'swm', 'tar', 'taz', 'tbz', 'tbz2', 'tgz',
        'tpz', 'txz', 'vhd', 'vhdx', 'wim', 'xar', 'xz', 'z', 'zip'
    )

    $changes = New-Object 'System.Collections.Generic.List[object]'
    foreach ($extension in $extensions) {
        $progId = "7-Zip.$extension"
        if (Test-AtlasMachineClassRegistration -ProgId $progId) {
            $changes.Add((New-AtlasFileAssociationChange `
                -Path "SOFTWARE\Classes\.$extension\OpenWithProgids" `
                -Name $progId `
                -Value '' `
                -Kind ([Microsoft.Win32.RegistryValueKind]::String)))
        }
    }

    if ($changes.Count -gt 0) {
        $changes.Add((New-AtlasFileAssociationChange `
            -Path 'SOFTWARE\7-Zip\Options' `
            -Name 'ContextMenu' `
            -Value 1073746726 `
            -Kind ([Microsoft.Win32.RegistryValueKind]::DWord)))
    }

    return $changes.ToArray()
}

function Write-AtlasFileAssociationChange {
    <#
    .SYNOPSIS
        Writes one planned value into the current user's hive through the process token.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Change
    )

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

function Set-AtlasFileAssociations {
    <#
    .SYNOPSIS
        Advertises installed archive handlers for the current user and reports the
        association plan; browser defaults stay user-controlled.
    .DESCRIPTION
        Runs as the signed-in, non-elevated user. With -PlanOnly the plan is returned
        without any token check or registry write; otherwise the token must match
        -ExpectedUserSid (when given) and be an interactive non-service, non-elevated
        account. Every write is idempotent, so rerunning is the recovery path.
    #>
    param(
        [ValidateSet('Base', 'Microsoft Edge', 'Brave', 'LibreWolf', 'Firefox', 'Google Chrome')]
        [string]$AssociationProfile = 'Base',

        [AllowNull()]
        [AllowEmptyString()]
        [string]$ExpectedUserSid,

        [switch]$PlanOnly
    )

    $changes = @(Get-AtlasArchiveAssociationChange)
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
        return $result
    }

    Assert-AtlasFileAssociationUser -ExpectedUserSid $ExpectedUserSid
    if ($browserDefaultRequested) {
        Write-AtlasLog -Level Warning -Message "The '$AssociationProfile' browser default remains user-controlled. Open ms-settings:defaultapps or use documented provisioning policy."
    }

    foreach ($change in $changes) {
        Write-AtlasFileAssociationChange -Change $change
    }
    return $result
}
