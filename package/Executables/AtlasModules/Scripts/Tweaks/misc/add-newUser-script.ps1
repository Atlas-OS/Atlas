# Companion of add-newUser-script.psd1. Revokes Builtin Users write access on the
# retired HKLM UserSetup marker; its values are never read. Uses .NET, not Get-Acl:
# Get-Acl -LiteralPath rewrites a registry PSPath and then reports the key missing.
$ErrorActionPreference = 'Stop'

# Revoke only explicit allow rules for Builtin Users. Never enumerate, migrate, or
# delete values in this historically user-writable key: none can be authenticated.
# The key must be open with ReadPermissions and ChangePermissions.
function Revoke-AtlasLegacyMarkerUserAccess([Microsoft.Win32.RegistryKey]$Key) {
    $usersSid = 'S-1-5-32-545'
    $accessSections = [Security.AccessControl.AccessControlSections]::Access
    $acl = $Key.GetAccessControl($accessSections)
    $aclChanged = $false
    foreach ($rule in @($acl.GetAccessRules(
                $true,
                $false,
                [Security.Principal.SecurityIdentifier]
            ))) {
        if ($rule.IdentityReference.Value -ceq $usersSid -and
            $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow) {
            [void]$acl.RemoveAccessRuleSpecific($rule)
            $aclChanged = $true
        }
    }
    if ($aclChanged) {
        $Key.SetAccessControl($acl)
    }

    # Fail closed if a write-capable Users rule survives through inheritance or an ACL
    # publication failure. Read-only legacy access is harmless because values are ignored.
    # Only bits that grant a write count: SetValue, CreateSubKey, CreateLink, DELETE,
    # WRITE_DAC, WRITE_OWNER, GENERIC_ALL and GENERIC_WRITE. WriteKey and FullControl
    # also carry read bits, so they would match the Users read rule that keys under
    # HKLM\SOFTWARE normally inherit.
    $writeMask = 0x500D0026
    $publishedAcl = $Key.GetAccessControl($accessSections)
    foreach ($rule in @($publishedAcl.GetAccessRules(
                $true,
                $true,
                [Security.Principal.SecurityIdentifier]
            ))) {
        if ($rule.IdentityReference.Value -ceq $usersSid -and
            $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            (([int]$rule.RegistryRights -band $writeMask) -ne 0)) {
            throw 'The legacy machine UserSetup marker still grants write access to Builtin Users.'
        }
    }
}

# SYSTEM and TrustedInstaller append the install log in AtlasModules\Logs, so
# remove the explicit Builtin Users grant pre-release builds put there. Processes
# that are not elevated log to their own profile instead.
function Revoke-AtlasInstallLogUserAccess([string]$Path) {
    $icaclsPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'icacls.exe')
    if (-not [IO.File]::Exists($icaclsPath)) {
        throw "The inbox ACL utility is missing at '$icaclsPath'."
    }

    & $icaclsPath $Path /remove:g '*S-1-5-32-545' /T /Q | Out-Null
    $icaclsExitCode = $LASTEXITCODE
    if ($icaclsExitCode -ne 0) {
        throw "icacls.exe failed to revoke Builtin Users access to the install logs with exit code $icaclsExitCode."
    }
}

$aclRights = [Security.AccessControl.RegistryRights]::ReadPermissions -bor
    [Security.AccessControl.RegistryRights]::ChangePermissions
$legacyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    'SOFTWARE\AtlasOS\UserSetup',
    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
    $aclRights)
if ($null -ne $legacyKey) {
    try {
        Revoke-AtlasLegacyMarkerUserAccess $legacyKey
    }
    finally {
        $legacyKey.Close()
    }
}

$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
    throw 'The protected Windows directory is unavailable for install-log ACL repair.'
}
$installLogsPath = [IO.Path]::Combine($windowsRoot, 'AtlasModules', 'Logs')
if ([IO.Directory]::Exists($installLogsPath)) {
    Revoke-AtlasInstallLogUserAccess $installLogsPath
}
