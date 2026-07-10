# Atlas.Registry domain: registry path parsing, HKCU redirection and user hive enumeration.
#
# AME Wizard runs actions as TrustedInstaller (SYSTEM, S-1-5-18). In that context the
# ambient HKCU drive points at SYSTEM's hive, so HKCU paths must be resolved explicitly
# to the interactive user's hive under HKEY_USERS and mirrored into the default-user
# hive (HKU\AME_UserHive_Default) that the install keeps loaded for new accounts.

$script:AtlasActiveUserSid = $null
$script:AtlasDefaultUserHiveRoot = 'Registry::HKEY_USERS\AME_UserHive_Default'
$script:AtlasDefaultUserHiveName = 'AME_UserHive_Default'

function ConvertTo-AtlasRegistryPathInfo {
    <#
    .SYNOPSIS
        Parses a registry path in any common notation (HKCU:\, HKCU\, Registry::HKEY_...,
        HKU\...) into a canonical root name and subkey path.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $normalized = $Path.Trim().TrimEnd('\')
    if ($normalized -match '^(?i)Registry::(.*)$') {
        $normalized = $Matches[1]
    }

    $root = $normalized
    $subPath = ''
    $separatorIndex = $normalized.IndexOf('\')
    if ($separatorIndex -ge 0) {
        $root = $normalized.Substring(0, $separatorIndex)
        $subPath = $normalized.Substring($separatorIndex + 1).Trim('\')
    }

    $rootMap = @{
        'HKCU'                = 'HKEY_CURRENT_USER'
        'HKEY_CURRENT_USER'   = 'HKEY_CURRENT_USER'
        'HKLM'                = 'HKEY_LOCAL_MACHINE'
        'HKEY_LOCAL_MACHINE'  = 'HKEY_LOCAL_MACHINE'
        'HKU'                 = 'HKEY_USERS'
        'HKEY_USERS'          = 'HKEY_USERS'
        'HKCR'                = 'HKEY_CLASSES_ROOT'
        'HKEY_CLASSES_ROOT'   = 'HKEY_CLASSES_ROOT'
        'HKCC'                = 'HKEY_CURRENT_CONFIG'
        'HKEY_CURRENT_CONFIG' = 'HKEY_CURRENT_CONFIG'
    }

    $rootToken = $root.TrimEnd(':').ToUpperInvariant()
    if (-not $rootMap.ContainsKey($rootToken)) {
        throw "Unsupported registry root '$root' in path '$Path'."
    }

    return [pscustomobject]@{
        Root    = $rootMap[$rootToken]
        SubPath = $subPath
    }
}

function Resolve-AtlasRegistryPath {
    <#
    .SYNOPSIS
        Resolves a registry path to the provider path that should actually be written.
        With -RedirectHkcu, HKCU paths resolve to the given user's hive under HKEY_USERS
        and also produce the default-user-hive mirror path; other roots pass through.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string]$ActiveUserSid,

        [switch]$RedirectHkcu
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    $isHkcu = ($pathInfo.Root -eq 'HKEY_CURRENT_USER')

    if ($isHkcu -and $RedirectHkcu) {
        if ([string]::IsNullOrEmpty($ActiveUserSid)) {
            throw "An active user SID is required to redirect the HKCU path '$Path'."
        }

        $userRoot = "Registry::HKEY_USERS\$ActiveUserSid"
        $mirrorRoot = $script:AtlasDefaultUserHiveRoot
        $primary = $userRoot
        $mirror = $mirrorRoot
        if ($pathInfo.SubPath) {
            $primary = "$userRoot\$($pathInfo.SubPath)"
            $mirror = "$mirrorRoot\$($pathInfo.SubPath)"
        }

        return [pscustomobject]@{
            Primary     = $primary
            Mirror      = $mirror
            HkcuSubPath = $pathInfo.SubPath
            IsHkcu      = $true
        }
    }

    $primary = "Registry::$($pathInfo.Root)"
    if ($pathInfo.SubPath) {
        $primary = "Registry::$($pathInfo.Root)\$($pathInfo.SubPath)"
    }

    return [pscustomobject]@{
        Primary     = $primary
        Mirror      = $null
        HkcuSubPath = $null
        IsHkcu      = $isHkcu
    }
}

function Resolve-AtlasRegistryTarget {
    <#
    .SYNOPSIS
        Resolves a registry path for the current process context: HKCU is redirected to
        the active user's hive only when running as SYSTEM/TrustedInstaller (S-1-5-18);
        as a plain admin or user, the ambient HKCU drive is already correct.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $resolved = Resolve-AtlasRegistryPath -Path $Path
    if ($resolved.IsHkcu -and (Test-AtlasTrustedInstaller)) {
        $resolved = Resolve-AtlasRegistryPath -Path $Path -RedirectHkcu -ActiveUserSid (Get-AtlasActiveUserSid)
    }

    return $resolved
}

function Split-AtlasRegistryProviderPath {
    <#
    .SYNOPSIS
        Splits a provider path into a Microsoft.Win32 base registry key and a subkey path
        for direct .NET registry access (needed for value-kind fidelity and REG_NONE).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderPath
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $ProviderPath

    $baseKey = switch ($pathInfo.Root) {
        'HKEY_LOCAL_MACHINE' { [Microsoft.Win32.Registry]::LocalMachine }
        'HKEY_CURRENT_USER' { [Microsoft.Win32.Registry]::CurrentUser }
        'HKEY_USERS' { [Microsoft.Win32.Registry]::Users }
        'HKEY_CLASSES_ROOT' { [Microsoft.Win32.Registry]::ClassesRoot }
        'HKEY_CURRENT_CONFIG' { [Microsoft.Win32.Registry]::CurrentConfig }
    }

    return [pscustomobject]@{
        BaseKey = $baseKey
        SubPath = $pathInfo.SubPath
    }
}

function Get-AtlasActiveUserSid {
    <#
    .SYNOPSIS
        Returns the SID of the interactive user, resolved in order: the owner of
        explorer.exe, then the loaded S-1-5-21-* hive under HKEY_USERS that has a
        'Volatile Environment' key, then the single loaded user hive when exactly one
        exists (a guess that cannot be wrong). Otherwise throws - both when no user hive
        is loaded and when multiple hives are loaded with no signal to pick between them -
        because writing HKCU tweaks to the wrong hive must never happen silently.
    #>
    param(
        [switch]$Refresh
    )

    if ($script:AtlasActiveUserSid -and -not $Refresh) {
        return $script:AtlasActiveUserSid
    }

    $sid = $null
    try {
        $explorerProcesses = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'" -ErrorAction Stop)
        foreach ($process in $explorerProcesses) {
            try {
                $owner = Invoke-CimMethod -InputObject $process -MethodName GetOwner -ErrorAction Stop
                if ($owner.ReturnValue -ne 0 -or [string]::IsNullOrEmpty($owner.User)) {
                    continue
                }

                $account = New-Object System.Security.Principal.NTAccount($owner.Domain, $owner.User)
                $sid = $account.Translate([System.Security.Principal.SecurityIdentifier]).Value
                break
            }
            catch {
                $null = $_
            }
        }
    }
    catch {
        $null = $_
    }

    if (-not $sid) {
        $hiveKeys = @(Get-ChildItem -Path 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' })

        $chosen = $null
        foreach ($hiveKey in $hiveKeys) {
            if (Test-Path -LiteralPath (Join-Path -Path $hiveKey.PSPath -ChildPath 'Volatile Environment') -PathType Container) {
                $chosen = $hiveKey
                break
            }
        }

        if (-not $chosen) {
            if (@($hiveKeys).Count -eq 1) {
                # Exactly one loaded user hive: the guess cannot be wrong.
                $chosen = $hiveKeys[0]
            }
            elseif (@($hiveKeys).Count -gt 1) {
                $hiveList = ($hiveKeys | ForEach-Object { $_.PSChildName }) -join ', '
                throw "Could not determine the active user SID: no explorer.exe owner could be resolved and multiple user hives are loaded ($hiveList). Refusing to guess - HKCU tweaks would land in an arbitrary user's profile."
            }
        }

        if ($chosen) {
            $sid = $chosen.PSChildName
        }
    }

    if (-not $sid) {
        throw 'Could not determine the active user SID: no explorer.exe owner could be resolved and no S-1-5-21-* user hive is loaded under HKEY_USERS.'
    }

    $script:AtlasActiveUserSid = $sid
    return $sid
}

function Get-AtlasUserHives {
    <#
    .SYNOPSIS
        Returns Registry:: provider paths for every real user hive loaded under
        HKEY_USERS (S-1-5-21-* SIDs, excluding the _Classes hives and built-in accounts).
    #>
    $hives = @(Get-ChildItem -Path 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' })

    $paths = @()
    foreach ($hive in $hives) {
        $paths += "Registry::HKEY_USERS\$($hive.PSChildName)"
    }

    return $paths
}

function Get-RegUserPaths {
    <#
    .SYNOPSIS
        Returns the registry key objects for loaded user hives under HKU (and the AME
        default-user hives), optionally filtered to proper users via their
        'Volatile Environment' key.
    #>
    param(
        [switch]$DontCheckEnv,
        [switch]$NoDefault
    )

    $regPattern = 'Volatile Environment|AME_UserHive_'
    if ($NoDefault) { $regPattern = "$regPattern[1-9].*" }
    $initPaths = @(Get-ChildItem -Path 'Registry::HKU' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "S-[0-9-]+(?!.*_)|$regPattern" })

    # If the 'Volatile Environment' key exists, that means it is a proper user.
    # Built-in accounts/SIDs don't have this key.
    $paths = @()
    if (-not $DontCheckEnv) {
        foreach ($userKey in $initPaths) {
            $envKeys = @(Get-ChildItem -Path $userKey.PSPath -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $regPattern })
            if (@($envKeys).Count -ne 0) {
                $paths += $userKey
            }
        }
    }
    else {
        $paths = $initPaths
    }

    return $paths
}

function Invoke-AtlasRegistryTargetOperation {
    <#
    .SYNOPSIS
        Runs a registry operation against the resolved target of a path, records the
        exact typed mutation for redirected HKCU paths, and repeats the operation
        against the default-user hive mirror when that hive is loaded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$Delta
    )

    $resolved = Resolve-AtlasRegistryTarget -Path $Path
    & $Action $resolved.Primary

    if ($null -ne $resolved.HkcuSubPath) {
        try {
            $deltaParameters = @{
                SubPath   = $resolved.HkcuSubPath
                Operation = $Delta['Operation']
            }
            foreach ($propertyName in @('Name', 'Kind', 'Data')) {
                if ($Delta.ContainsKey($propertyName)) {
                    $deltaParameters[$propertyName] = $Delta[$propertyName]
                }
            }

            Write-AtlasHkcuDeltaRecord @deltaParameters
        }
        catch {
            throw (New-AtlasHkcuDeltaFailureException -SubPath $resolved.HkcuSubPath -InnerException $_.Exception)
        }

        if ($resolved.Mirror -and (Test-Path -LiteralPath $script:AtlasDefaultUserHiveRoot)) {
            try {
                & $Action $resolved.Mirror
            }
            catch {
                Write-AtlasLog -Message "Default-user-hive mirror operation failed for '$($resolved.Mirror)': $($_.Exception.Message)" -Level Warning
            }
        }
    }
}
