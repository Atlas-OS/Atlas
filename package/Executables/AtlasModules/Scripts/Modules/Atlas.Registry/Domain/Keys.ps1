# Atlas.Registry domain: registry key creation and removal, and taking back a
# default-user policy key whose permissions refuse Atlas.

function Get-AtlasDefaultUserPolicyRootDepth {
    <#
    .SYNOPSIS
        For a key under the loaded default-user hive's Software\Policies, the number of
        path segments up to and including Policies (3); otherwise 0. Only keys below that
        depth are Atlas's to take back.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderPath
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $ProviderPath
    $prefix = "$script:AtlasDefaultUserHiveName\Software\Policies\"
    if ($pathInfo.Root -ceq 'HKEY_USERS' -and
        $pathInfo.SubPath.Length -gt $prefix.Length -and
        $pathInfo.SubPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return 3
    }
    return 0
}

function Enable-AtlasRegistryOwnershipPrivilege {
    Initialize-AtlasNativeType
    [Atlas.Native.OwnershipPrivilege]::Enable()
}

function Repair-AtlasDefaultUserPolicyKeyAccess {
    <#
    .SYNOPSIS
        Takes ownership of the deepest existing key on a default-user policy path and
        resets its permissions to inherit from its parent, and returns that key's path.
        Returns $null when no key below the policy root exists to take back.
    .DESCRIPTION
        A policy key an earlier Atlas or another tool wrote into the default-user hive
        can carry permissions that refuse even TrustedInstaller. The key only ever holds
        policy values, so inheriting its parent's permissions, as a key Windows creates
        there does, is what it should have.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubPath,

        # Keys at this depth or above are left alone.
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 64)]
        [int]$ProtectedDepth
    )

    $segments = @($SubPath.Split([char]'\') | Where-Object { $_ })
    $target = $null
    for ($depth = $segments.Count; $depth -gt $ProtectedDepth -and $null -eq $target; $depth--) {
        $candidate = $segments[0..($depth - 1)] -join '\'
        try {
            $probe = $BaseKey.OpenSubKey($candidate, $false)
            if ($null -ne $probe) {
                $probe.Close()
                $target = $candidate
            }
        }
        catch [System.Security.SecurityException], [System.UnauthorizedAccessException] {
            # It exists, and refuses even reading.
            $target = $candidate
        }
    }
    if ($null -eq $target) {
        return $null
    }

    Enable-AtlasRegistryOwnershipPrivilege
    $self = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $check = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree
    $key = $BaseKey.OpenSubKey($target, $check, [Security.AccessControl.RegistryRights]::TakeOwnership)
    try {
        $owner = New-Object Security.AccessControl.RegistrySecurity
        $owner.SetOwner($self)
        $key.SetAccessControl($owner)
    }
    finally { $key.Close() }

    $key = $BaseKey.OpenSubKey($target, $check, [Security.AccessControl.RegistryRights]'ReadPermissions, ChangePermissions')
    try {
        # An empty DACL that isn't protected takes the parent's inheritable permissions.
        $inherited = New-Object Security.AccessControl.RegistrySecurity
        $inherited.SetSecurityDescriptorSddlForm('D:', [Security.AccessControl.AccessControlSections]::Access)
        $key.SetAccessControl($inherited)
    }
    finally { $key.Close() }
    return $target
}

function Open-AtlasRefusedPolicyKey {
    <#
    .SYNOPSIS
        Takes back the default-user policy key that refused a write and opens it for
        writing, or stops with what the user can do.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateNotNull()][psobject]$Split,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ProviderPath,
        [Parameter(Mandatory = $true)][ValidateRange(1, 64)][int]$ProtectedDepth
    )

    $repaired = $null
    try {
        $repaired = Repair-AtlasDefaultUserPolicyKeyAccess -BaseKey $Split.BaseKey -SubPath $Split.SubPath -ProtectedDepth $ProtectedDepth
    }
    catch {
        throw "Windows refused Atlas access to the default-user policy key '$ProviderPath', and Atlas couldn't take it back: $($_.Exception.Message) Its permissions were changed outside Atlas. Reset them with Registry Editor, or remove the key, then try installing Atlas again."
    }
    if ($null -eq $repaired) {
        throw "Windows refused Atlas access to the default-user policy key '$ProviderPath', and no key under the default user's policies exists for Atlas to take back. Reset the permissions of the default user's Software\Policies key with Registry Editor, then try installing Atlas again."
    }
    Write-AtlasLog -Message "Took ownership of the default-user policy key '$($Split.BaseKey.Name)\$repaired' and reset its permissions to inherit from its parent, because they refused Atlas."
    try {
        $key = $Split.BaseKey.CreateSubKey($Split.SubPath)
    }
    catch [System.UnauthorizedAccessException], [System.Security.SecurityException] {
        throw "Windows still refuses Atlas access to the default-user policy key '$ProviderPath' after Atlas took ownership of '$repaired' and reset its permissions. Reset them with Registry Editor, or remove the key, then try installing Atlas again."
    }
    if ($null -eq $key) {
        throw "Failed to create or open the registry key '$ProviderPath'."
    }
    return $key
}

function New-AtlasRegistryKey {
    <#
    .SYNOPSIS
        Creates a registry key (and any missing parents). HKCU is either the proven
        current token's ambient hive or the explicitly bound fixed default-user hive.
        An existing key is not an error.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Invoke-AtlasRegistryTargetOperation -Path $Path -Action {
        param($providerPath)

        $split = Split-AtlasRegistryProviderPath -ProviderPath $providerPath
        if (-not $split.SubPath) {
            return
        }

        $key = $split.BaseKey.CreateSubKey($split.SubPath)
        if ($null -eq $key) {
            throw "Failed to create the registry key '$providerPath'."
        }

        $key.Close()
    }
}

function Remove-AtlasRegistryKey {
    <#
    .SYNOPSIS
        Recursively deletes a registry key if it exists (a missing key is not an error),
        with the same token/default-user scope binding as
        New-AtlasRegistryKey.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    # A bare HKCU resolves to a whole user hive under HKU, which the root check
    # inside the action cannot see.
    if ($pathInfo.Root -eq 'HKEY_CURRENT_USER' -and [string]::IsNullOrEmpty($pathInfo.SubPath)) {
        throw "Refusing to delete the registry root '$Path'."
    }

    Invoke-AtlasRegistryTargetOperation -Path $Path -Action {
        param($providerPath)

        $split = Split-AtlasRegistryProviderPath -ProviderPath $providerPath
        if (-not $split.SubPath) {
            throw "Refusing to delete the registry root '$providerPath'."
        }

        # The second argument suppresses the missing-key exception.
        $split.BaseKey.DeleteSubKeyTree($split.SubPath, $false)
    }
}
