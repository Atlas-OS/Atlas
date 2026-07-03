# Atlas.Registry domain: default-user-hive re-sync.
#
# Strict superset of the retired Executables\APPLYDUHIVE.ps1: instead of regex-scraping
# tweak YAML for HKCU paths, the paths are the ones actually written through this module
# (recorded in hkcu-paths.log), and each recorded key is copied from the active user's
# hive into HKU\AME_UserHive_Default with value kinds preserved.

function Copy-AtlasRegistryKeyValues {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceSubPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationSubPath
    )

    $sourceKey = $null
    $destinationKey = $null
    try {
        $sourceKey = [Microsoft.Win32.Registry]::Users.OpenSubKey($SourceSubPath, $false)
        if ($null -eq $sourceKey) {
            return
        }

        $destinationKey = [Microsoft.Win32.Registry]::Users.CreateSubKey($DestinationSubPath)
        if ($null -eq $destinationKey) {
            Write-AtlasLog -Message "Failed to create the default-user-hive key 'HKU\$DestinationSubPath'." -Level Warning
            return
        }

        foreach ($valueName in $sourceKey.GetValueNames()) {
            $value = $sourceKey.GetValue($valueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $kind = $sourceKey.GetValueKind($valueName)
            $destinationKey.SetValue($valueName, $value, $kind)
        }
    }
    finally {
        if ($null -ne $destinationKey) {
            $destinationKey.Close()
        }
        if ($null -ne $sourceKey) {
            $sourceKey.Close()
        }
    }
}

function Sync-AtlasDefaultUserHive {
    <#
    .SYNOPSIS
        Re-copies every HKCU key recorded in hkcu-paths.log from the active user's hive
        into the loaded default-user hive (HKU\AME_UserHive_Default), creating keys as
        needed and preserving value kinds. Missing source keys are skipped; when the
        default-user hive is not loaded, a warning is logged and nothing happens.
    #>
    $logFilePath = Join-Path -Path (Join-Path -Path (Get-AtlasContext).LogsPath -ChildPath 'install') -ChildPath 'hkcu-paths.log'
    if (-not (Test-Path -LiteralPath $logFilePath -PathType Leaf)) {
        Write-AtlasLog -Message 'No recorded HKCU paths to sync into the default-user hive.'
        return
    }

    if (-not (Test-Path -LiteralPath $script:AtlasDefaultUserHiveRoot)) {
        Write-AtlasLog -Message "The default-user hive is not loaded at 'HKU\$script:AtlasDefaultUserHiveName'; skipping the default-user-hive sync." -Level Warning
        return
    }

    $activeUserSid = Get-AtlasActiveUserSid

    $subPaths = @(Get-Content -LiteralPath $logFilePath -ErrorAction Stop |
        ForEach-Object { "$_".Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique)

    Write-AtlasLog -Message "Syncing $(@($subPaths).Count) recorded HKCU key path(s) into the default-user hive."

    foreach ($subPath in $subPaths) {
        try {
            Copy-AtlasRegistryKeyValues -SourceSubPath "$activeUserSid\$subPath" -DestinationSubPath "$script:AtlasDefaultUserHiveName\$subPath"
        }
        catch {
            Write-AtlasLog -Message "Failed to sync the HKCU key '$subPath' into the default-user hive: $($_.Exception.Message)" -Level Warning
        }
    }
}
