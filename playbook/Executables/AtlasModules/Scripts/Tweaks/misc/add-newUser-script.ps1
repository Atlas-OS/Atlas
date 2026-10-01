# Companion of add-newUser-script.psd1. Revokes Builtin Users write access on the
# retired HKLM UserSetup marker; its values are never read. Uses .NET, not Get-Acl:
# Get-Acl -LiteralPath rewrites a registry PSPath and then reports the key missing.
$ErrorActionPreference = 'Stop'

$legacyMarkerSubKey = 'SOFTWARE\AtlasOS\UserSetup'
$usersSid = New-Object -TypeName Security.Principal.SecurityIdentifier `
    -ArgumentList 'S-1-5-32-545'
$aclRights = [Security.AccessControl.RegistryRights]::ReadPermissions -bor
    [Security.AccessControl.RegistryRights]::ChangePermissions
$legacyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    $legacyMarkerSubKey,
    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
    $aclRights)
if ($null -ne $legacyKey) {
    try {
        # Revoke only explicit allow rules for Builtin Users. Never enumerate, migrate, or
        # delete values in this historically user-writable key: none can be authenticated.
        $accessSections = [Security.AccessControl.AccessControlSections]::Access
        $legacyAcl = $legacyKey.GetAccessControl($accessSections)
        $aclChanged = $false
        foreach ($rule in @($legacyAcl.GetAccessRules(
                    $true,
                    $false,
                    [Security.Principal.SecurityIdentifier]
                ))) {
            if ($rule.IdentityReference.Value -ceq $usersSid.Value -and
                $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow) {
                [void]$legacyAcl.RemoveAccessRuleSpecific($rule)
                $aclChanged = $true
            }
        }
        if ($aclChanged) {
            $legacyKey.SetAccessControl($legacyAcl)
        }

        # Fail closed if a write-capable Users rule survives through inheritance or an ACL
        # publication failure. Read-only legacy access is harmless because values are ignored.
        $writeRights = [Security.AccessControl.RegistryRights]::SetValue -bor
            [Security.AccessControl.RegistryRights]::CreateSubKey -bor
            [Security.AccessControl.RegistryRights]::WriteKey -bor
            [Security.AccessControl.RegistryRights]::ChangePermissions -bor
            [Security.AccessControl.RegistryRights]::TakeOwnership -bor
            [Security.AccessControl.RegistryRights]::FullControl
        $publishedAcl = $legacyKey.GetAccessControl($accessSections)
        foreach ($rule in @($publishedAcl.GetAccessRules(
                    $true,
                    $true,
                    [Security.Principal.SecurityIdentifier]
                ))) {
            if ($rule.IdentityReference.Value -ceq $usersSid.Value -and
                $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
                (($rule.RegistryRights -band $writeRights) -ne 0)) {
                throw 'The legacy machine UserSetup marker still grants write access to Builtin Users.'
            }
        }
    }
    finally {
        $legacyKey.Close()
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

$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
    throw 'The protected Windows directory is unavailable for install-log ACL repair.'
}
$installLogsPath = [IO.Path]::Combine($windowsRoot, 'AtlasModules', 'Logs')
if ([IO.Directory]::Exists($installLogsPath)) {
    Revoke-AtlasInstallLogUserAccess $installLogsPath
}
