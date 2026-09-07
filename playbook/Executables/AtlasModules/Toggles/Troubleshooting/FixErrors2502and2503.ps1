function Invoke-AtlasWindowsTempPermissionsRepair {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasNote -Text @(
            'Installer errors 2502 and 2503 come from wrong permissions on the Windows TEMP folder.'
            'They are not caused by Atlas; this resets those permissions.'
        )
        Write-AtlasStep -Text 'Repairing the Windows TEMP folder permissions...'
    }

    Import-AtlasModule -Name Atlas.Security
    Repair-AtlasWindowsTempPermissions
}
