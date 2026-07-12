# Companion of add-newUser-script.psd1. Initialize-NewUser now keeps its completion
# state exclusively in the exact user's HKCU hive. Do not recreate or consume the old
# shared HKLM UserSetup marker: its historical Builtin Users write ACL made every value
# in that key forgeable by another local account.
$ErrorActionPreference = 'Stop'

$legacyMarkerPath = 'HKLM:\SOFTWARE\AtlasOS\UserSetup'
if (Test-Path -LiteralPath $legacyMarkerPath) {
    # Revoke only explicit allow rules for Builtin Users. Never enumerate, migrate, or
    # delete values in this historically user-writable key: none can be authenticated.
    $usersSid = New-Object -TypeName Security.Principal.SecurityIdentifier `
        -ArgumentList 'S-1-5-32-545'
    $legacyAcl = Get-Acl -LiteralPath $legacyMarkerPath
    $aclChanged = $false
    foreach ($rule in @($legacyAcl.GetAccessRules(
                $true,
                $false,
                [Security.Principal.SecurityIdentifier]
            ))) {
        if ($rule.IdentityReference.Value -ceq $usersSid.Value -and
            $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow) {
            $legacyAcl.RemoveAccessRuleSpecific($rule)
            $aclChanged = $true
        }
    }
    if ($aclChanged) {
        Set-Acl -LiteralPath $legacyMarkerPath -AclObject $legacyAcl -ErrorAction Stop
    }

    # Fail closed if a write-capable Users rule survives through inheritance or an ACL
    # publication failure. Read-only legacy access is harmless because values are ignored.
    $writeRights = [Security.AccessControl.RegistryRights]::SetValue -bor
        [Security.AccessControl.RegistryRights]::CreateSubKey -bor
        [Security.AccessControl.RegistryRights]::WriteKey -bor
        [Security.AccessControl.RegistryRights]::ChangePermissions -bor
        [Security.AccessControl.RegistryRights]::TakeOwnership -bor
        [Security.AccessControl.RegistryRights]::FullControl
    $publishedAcl = Get-Acl -LiteralPath $legacyMarkerPath
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

$windowsRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
if ([string]::IsNullOrWhiteSpace($windowsRoot)) {
    throw 'The protected Windows directory is unavailable for install-log ACL publication.'
}
$installLogsPath = [IO.Path]::Combine($windowsRoot, 'AtlasModules', 'Logs')
if ([IO.Directory]::Exists($installLogsPath)) {
    $icaclsPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'icacls.exe')
    if (-not [IO.File]::Exists($icaclsPath)) {
        throw "The inbox ACL utility is missing at '$icaclsPath'."
    }

    & $icaclsPath $installLogsPath /grant '*S-1-5-32-545:(OI)(CI)M' /T | Out-Null
    $icaclsExitCode = $LASTEXITCODE
    if ($icaclsExitCode -ne 0) {
        throw "icacls.exe failed to grant first-logon log access with exit code $icaclsExitCode."
    }
}
