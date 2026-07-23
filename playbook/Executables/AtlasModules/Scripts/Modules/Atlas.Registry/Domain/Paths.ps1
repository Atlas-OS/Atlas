# Atlas.Registry domain: registry path parsing and explicit HKCU scope binding.
#
# A privileged process must never generally redirect HKCU to a live user's HKEY_USERS
# path. A user can create registry links inside their own hive, so an otherwise exact
# SID still leaves TrustedInstaller acting as a deputy over user-controlled traversal.
# Live-user mutations therefore run in that user's own medium-token process and use
# ambient HKCU. The sole live-user exception is an install-state-bound writer restricted
# to the two Windows-owned policy roots whose ACLs reject the medium-token user. It runs
# in a short-lived process and cannot resolve any other HKCU path.

$script:AtlasRegistryIdentityContext = $null
$script:AtlasDefaultUserHiveRoot = 'Registry::HKEY_USERS\Atlas_DefaultUser'
$script:AtlasDefaultUserHiveName = 'Atlas_DefaultUser'

function Test-AtlasDefaultUserHiveLoaded {
    $usersKey = [Microsoft.Win32.Registry]::Users
    $hiveKey = $usersKey.OpenSubKey($script:AtlasDefaultUserHiveName, $false)
    if ($null -eq $hiveKey) {
        return $false
    }
    $hiveKey.Dispose()
    return $true
}

function Test-AtlasProtectedCurrentUserPolicyPath {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubPath
    )

    $normalized = $SubPath.Trim('\')
    return (
        $normalized -imatch '^Software\\Policies(?:\\|$)' -or
        $normalized -imatch '^Software\\Microsoft\\Windows\\CurrentVersion\\Policies(?:\\|$)'
    )
}

function ConvertTo-AtlasCanonicalRegistrySid {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Sid,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label
    )

    try {
        $canonicalSid = New-Object Security.Principal.SecurityIdentifier($Sid)
    }
    catch {
        throw "$Label '$Sid' is not a valid Windows SID."
    }

    if (-not [string]::Equals($canonicalSid.Value, $Sid, [StringComparison]::Ordinal)) {
        throw "$Label '$Sid' is not canonical."
    }

    return $canonicalSid.Value
}

function Get-AtlasRegistryCurrentTokenSid {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($null -eq $identity -or $null -eq $identity.User) {
        throw 'The current process token has no user SID; refusing to resolve HKCU.'
    }

    return ConvertTo-AtlasCanonicalRegistrySid -Sid $identity.User.Value `
        -Label 'Current process token SID'
}

function Initialize-AtlasRegistryIdentityContext {
    <#
    .SYNOPSIS
        Binds HKCU operations to either the current process token or the fixed Atlas
        default-user hive. The binding is immutable for the module lifetime.
    .DESCRIPTION
        CurrentToken is used by an exact user process and never redirects through HKU.
        DefaultUserOnly is accepted only from strict TrustedInstaller and is bound to
        the active install state. InstallingUserPoliciesOnly is also strict
        TrustedInstaller and transaction-bound, but may resolve only the fixed Windows
        policy roots beneath the exact installing-user SID.
    #>
    [CmdletBinding(DefaultParameterSetName = 'CurrentToken')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'CurrentToken')]
        [switch]$CurrentToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'CurrentToken')]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedUserSid,

        [Parameter(Mandatory = $true, ParameterSetName = 'DefaultUserOnly')]
        [switch]$DefaultUserOnly,

        [Parameter(Mandatory = $true, ParameterSetName = 'DefaultUserOnly')]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true, ParameterSetName = 'InstallingUserPoliciesOnly')]
        [string]$TransactionId,

        [Parameter(Mandatory = $true, ParameterSetName = 'InstallingUserPoliciesOnly')]
        [switch]$InstallingUserPoliciesOnly,

        [Parameter(Mandatory = $true, ParameterSetName = 'InstallingUserPoliciesOnly')]
        [ValidateNotNullOrEmpty()]
        [string]$InstallingUserSid
    )

    $newContext = $null
    switch ($PSCmdlet.ParameterSetName) {
        'CurrentToken' {
            if (-not $CurrentToken) {
                throw 'CurrentToken registry identity context requires -CurrentToken:$true.'
            }
            if (Test-AtlasSystem) {
                throw 'CurrentToken registry identity context cannot be initialized from LocalSystem or TrustedInstaller.'
            }

            $expectedSid = ConvertTo-AtlasCanonicalRegistrySid -Sid $ExpectedUserSid `
                -Label 'Expected current-user SID'
            $actualSid = Get-AtlasRegistryCurrentTokenSid
            if (-not [string]::Equals($actualSid, $expectedSid, [StringComparison]::Ordinal)) {
                throw "The current process token SID '$actualSid' does not match expected user SID '$expectedSid'."
            }

            $newContext = [pscustomobject]@{
                Mode          = 'CurrentToken'
                UserSid       = $actualSid
                TransactionId = $null
            }
        }
        'DefaultUserOnly' {
            if (-not $DefaultUserOnly) {
                throw 'DefaultUserOnly registry identity context requires -DefaultUserOnly:$true.'
            }
            if (-not (Test-AtlasTrustedInstaller)) {
                throw 'DefaultUserOnly registry identity context requires strict TrustedInstaller token evidence.'
            }

            $transaction = Get-AtlasContext -Refresh
            if (-not [bool]$transaction.IsInstallStateBacked) {
                throw 'DefaultUserOnly registry identity requires an active Atlas install state.'
            }
            if (-not [string]::Equals(
                    [string]$transaction.TransactionId,
                    $TransactionId,
                    [StringComparison]::Ordinal
                )) {
                throw "The active Atlas transaction '$($transaction.TransactionId)' does not match expected transaction '$TransactionId'."
            }

            $newContext = [pscustomobject]@{
                Mode          = 'DefaultUserOnly'
                UserSid       = $null
                TransactionId = [string]$transaction.TransactionId
            }
        }
        'InstallingUserPoliciesOnly' {
            if (-not $InstallingUserPoliciesOnly) {
                throw 'InstallingUserPoliciesOnly registry identity context requires -InstallingUserPoliciesOnly:$true.'
            }
            if (-not (Test-AtlasTrustedInstaller)) {
                throw 'InstallingUserPoliciesOnly registry identity context requires strict TrustedInstaller token evidence.'
            }

            $expectedSid = ConvertTo-AtlasCanonicalRegistrySid -Sid $InstallingUserSid `
                -Label 'Expected installing-user SID'
            $transaction = Get-AtlasContext -Refresh
            if (-not [bool]$transaction.IsInstallStateBacked) {
                throw 'InstallingUserPoliciesOnly registry identity requires an active Atlas install state.'
            }
            if (-not [string]::Equals(
                    [string]$transaction.TransactionId,
                    $TransactionId,
                    [StringComparison]::Ordinal
                )) {
                throw "The active Atlas transaction '$($transaction.TransactionId)' does not match expected transaction '$TransactionId'."
            }
            if ([string]::IsNullOrWhiteSpace([string]$transaction.InteractiveUserSid)) {
                throw 'The active Atlas install state has no installing-user SID.'
            }
            $activeSid = ConvertTo-AtlasCanonicalRegistrySid `
                -Sid ([string]$transaction.InteractiveUserSid) -Label 'Active installing-user SID'
            if (-not [string]::Equals($activeSid, $expectedSid, [StringComparison]::Ordinal)) {
                throw "The active installing-user SID '$activeSid' does not match expected SID '$expectedSid'."
            }

            $newContext = [pscustomobject]@{
                Mode          = 'InstallingUserPoliciesOnly'
                UserSid       = $activeSid
                TransactionId = [string]$transaction.TransactionId
            }
        }
    }

    if ($null -ne $script:AtlasRegistryIdentityContext) {
        if ([string]$script:AtlasRegistryIdentityContext.Mode -cne [string]$newContext.Mode -or
            [string]$script:AtlasRegistryIdentityContext.UserSid -cne [string]$newContext.UserSid -or
            [string]$script:AtlasRegistryIdentityContext.TransactionId -cne [string]$newContext.TransactionId) {
            throw 'Atlas.Registry identity context is already initialized to a different immutable scope.'
        }

        return $script:AtlasRegistryIdentityContext
    }

    $script:AtlasRegistryIdentityContext = $newContext
    return $script:AtlasRegistryIdentityContext
}

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
        Normalizes a registry path without changing its identity scope. Privileged
        live-user HKU redirection is deliberately not part of this API.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    $isHkcu = ($pathInfo.Root -eq 'HKEY_CURRENT_USER')

    $primary = "Registry::$($pathInfo.Root)"
    if ($pathInfo.SubPath) {
        $primary = "Registry::$($pathInfo.Root)\$($pathInfo.SubPath)"
    }

    return [pscustomobject]@{
        Primary     = $primary
        HkcuSubPath = $null
        IsHkcu      = $isHkcu
    }
}

function Resolve-AtlasRegistryTarget {
    <#
    .SYNOPSIS
        Resolves a registry path for the explicitly proven process context. A
        non-System token uses only its own ambient HKCU. TrustedInstaller can resolve
        HKCU only after an explicit DefaultUserOnly transaction binding.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    $isSystem = Test-AtlasSystem

    if ($isSystem -and $pathInfo.Root -eq 'HKEY_USERS') {
        $hiveName = @($pathInfo.SubPath -split '\\', 2)[0]
        if ([string]::IsNullOrWhiteSpace($hiveName) -or
            $hiveName -cne $script:AtlasDefaultUserHiveName) {
            throw "A privileged Atlas.Registry caller may target only the fixed '$($script:AtlasDefaultUserHiveName)' HKEY_USERS hive, not '$Path'."
        }
    }

    if ($pathInfo.Root -ne 'HKEY_CURRENT_USER') {
        return Resolve-AtlasRegistryPath -Path $Path
    }

    if ($null -eq $script:AtlasRegistryIdentityContext) {
        if ($isSystem) {
            throw 'Privileged HKCU access has no explicit DefaultUserOnly identity context; live-user HKU redirection is forbidden.'
        }

        # This is not discovery: Windows binds ambient HKCU to the current process token.
        # Resolve the token SID on every operation so no process-global identity guess is
        # cached or reused after an embedding host changes impersonation state.
        $null = Get-AtlasRegistryCurrentTokenSid
        return Resolve-AtlasRegistryPath -Path $Path
    }

    switch ([string]$script:AtlasRegistryIdentityContext.Mode) {
        'CurrentToken' {
            if ($isSystem) {
                throw 'A CurrentToken registry identity context became privileged; refusing HKCU access.'
            }

            $actualSid = Get-AtlasRegistryCurrentTokenSid
            if (-not [string]::Equals(
                    $actualSid,
                    [string]$script:AtlasRegistryIdentityContext.UserSid,
                    [StringComparison]::Ordinal
                )) {
                throw 'The current process token changed after Atlas.Registry identity initialization.'
            }
            return Resolve-AtlasRegistryPath -Path $Path
        }
        'DefaultUserOnly' {
            if (-not $isSystem -or -not (Test-AtlasTrustedInstaller)) {
                throw 'The DefaultUserOnly registry identity context lost strict TrustedInstaller identity.'
            }
            if (-not (Test-AtlasDefaultUserHiveLoaded)) {
                throw "The fixed Atlas default-user hive is not loaded at '$($script:AtlasDefaultUserHiveRoot)'."
            }

            $primary = $script:AtlasDefaultUserHiveRoot
            if ($pathInfo.SubPath) {
                $primary = "$primary\$($pathInfo.SubPath)"
            }
            return [pscustomobject]@{
                Primary     = $primary
                HkcuSubPath = $pathInfo.SubPath
                IsHkcu      = $true
            }
        }
        'InstallingUserPoliciesOnly' {
            if (-not $isSystem -or -not (Test-AtlasTrustedInstaller)) {
                throw 'The InstallingUserPoliciesOnly registry identity context lost strict TrustedInstaller identity.'
            }
            if (-not (Test-AtlasProtectedCurrentUserPolicyPath -SubPath $pathInfo.SubPath)) {
                throw "The installing-user policy writer cannot target HKCU path '$Path'."
            }

            $primary = "Registry::HKEY_USERS\$($script:AtlasRegistryIdentityContext.UserSid)"
            if ($pathInfo.SubPath) {
                $primary = "$primary\$($pathInfo.SubPath)"
            }
            return [pscustomobject]@{
                Primary     = $primary
                HkcuSubPath = $pathInfo.SubPath
                IsHkcu      = $true
            }
        }
        default {
            throw "Unsupported Atlas.Registry identity context mode '$($script:AtlasRegistryIdentityContext.Mode)'."
        }
    }
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

function Invoke-AtlasRegistryTargetOperation {
    <#
    .SYNOPSIS
        Runs a registry operation against the explicitly resolved target of a path.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $resolved = Resolve-AtlasRegistryTarget -Path $Path
    & $Action $resolved.Primary
}
