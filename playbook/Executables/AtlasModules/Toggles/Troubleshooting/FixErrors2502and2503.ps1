function Show-AtlasWindowsTempRepairNote {
    param($Toggle)

    # The repair runs in the silent TrustedInstaller broker, so the explanation is
    # shown here, in the administrator window, before the broker starts.
    if ($Toggle.Silent) {
        throw 'The 2502 and 2503 explanation needs an interactive window.'
    }
    Write-AtlasNote -Text @(
        'Installer errors 2502 and 2503 come from wrong permissions on the Windows TEMP folder.'
        'They are not caused by Atlas; this resets those permissions.'
    )
    return 'Run'
}

function Invoke-AtlasWindowsTempPermissionsRepair {
    param($Toggle)

    [void]$Toggle
    Import-AtlasModule -Name Atlas.Security
    Repair-AtlasWindowsTempPermissions
}
