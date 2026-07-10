# Atlas.Registry domain: registry key creation and removal.

function New-AtlasRegistryKey {
    <#
    .SYNOPSIS
        Creates a registry key (and any missing parents). Under SYSTEM/TrustedInstaller,
        HKCU paths are redirected to the active user's hive and mirrored into the
        default-user hive when it is loaded. An existing key is not an error.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Invoke-AtlasRegistryTargetOperation -Path $Path -Delta @{
        Operation = 'CreateKey'
    } -Action {
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
        with the same HKCU redirection and default-user-hive mirroring as
        New-AtlasRegistryKey.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    if ($pathInfo.Root -eq 'HKEY_CURRENT_USER' -and [string]::IsNullOrEmpty($pathInfo.SubPath)) {
        throw "Refusing to delete the registry root '$Path'."
    }

    Invoke-AtlasRegistryTargetOperation -Path $Path -Delta @{
        Operation = 'DeleteKey'
    } -Action {
        param($providerPath)

        $split = Split-AtlasRegistryProviderPath -ProviderPath $providerPath
        if (-not $split.SubPath) {
            throw "Refusing to delete the registry root '$providerPath'."
        }

        # The second argument suppresses the missing-key exception.
        $split.BaseKey.DeleteSubKeyTree($split.SubPath, $false)
    }
}
