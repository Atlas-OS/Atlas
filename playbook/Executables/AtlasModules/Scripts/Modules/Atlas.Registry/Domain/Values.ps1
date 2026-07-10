# Atlas.Registry domain: registry value writes and deletes.
#
# Values are written through the Microsoft.Win32.Registry API instead of the provider
# cmdlets so the value kind is always explicit (including REG_NONE, which the provider
# cannot round-trip) and so redirected HKEY_USERS paths behave identically to drives.

function ConvertTo-AtlasDwordData {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    if ($Data -is [int]) {
        return $Data
    }

    # Values like 0xFFFFFFFF arrive as uint32/int64; reinterpret as a signed int32
    # because RegistryKey.SetValue(DWord) only accepts Int32.
    $unsigned = [uint32]$Data
    return [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes($unsigned), 0)
}

function ConvertTo-AtlasQwordData {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    if ($Data -is [long]) {
        return $Data
    }

    $unsigned = [uint64]$Data
    return [System.BitConverter]::ToInt64([System.BitConverter]::GetBytes($unsigned), 0)
}

function Set-AtlasRegistryValueCore {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderPath,

        # An empty Name writes the key's default value.
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')]
        [string]$Type,

        [object]$Data
    )

    # Assignments inside the switch keep array types intact; emitting arrays out of a
    # switch would unroll them through the pipeline and break the SetValue kind match.
    $value = $null
    switch ($Type) {
        'String' { $value = [string]$Data }
        'ExpandString' { $value = [string]$Data }
        'Binary' { $value = [byte[]]$Data }
        'DWord' { $value = ConvertTo-AtlasDwordData -Data $Data }
        'MultiString' { $value = [string[]]$Data }
        'QWord' { $value = ConvertTo-AtlasQwordData -Data $Data }
        'None' {
            if ($null -eq $Data) {
                $value = [byte[]]@()
            }
            else {
                $value = [byte[]]$Data
            }
        }
    }

    $split = Split-AtlasRegistryProviderPath -ProviderPath $ProviderPath
    $key = $split.BaseKey.CreateSubKey($split.SubPath)
    if ($null -eq $key) {
        throw "Failed to create or open the registry key '$ProviderPath'."
    }

    try {
        $key.SetValue($Name, $value, [Microsoft.Win32.RegistryValueKind]$Type)
    }
    finally {
        $key.Close()
    }
}

function Set-AtlasRegistryValue {
    <#
    .SYNOPSIS
        Writes a registry value, creating missing keys. An empty Name writes the key's
        default value. Under SYSTEM/TrustedInstaller, HKCU paths are redirected to the
        active user's hive and mirrored into the default-user hive
        (HKU\AME_UserHive_Default) when it is loaded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')]
        [string]$Type,

        [object]$Data
    )

    if ($null -eq $Data -and $Type -notin @('None', 'String', 'ExpandString')) {
        throw "Registry value '$Name' at '$Path' has type '$Type' but no data."
    }

    # The scriptblock resolves $Name/$Type/$Data dynamically from this function's scope.
    Invoke-AtlasRegistryTargetOperation -Path $Path -Delta @{
        Operation = 'SetValue'
        Name      = $Name
        Kind      = $Type
        Data      = $Data
    } -Action {
        param($providerPath)
        Set-AtlasRegistryValueCore -ProviderPath $providerPath -Name $Name -Type $Type -Data $Data
    }
}

function Remove-AtlasRegistryValue {
    <#
    .SYNOPSIS
        Deletes a registry value if it exists (a missing key or value is not an error),
        with the same HKCU redirection and default-user-hive mirroring as
        Set-AtlasRegistryValue.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name
    )

    Invoke-AtlasRegistryTargetOperation -Path $Path -Delta @{
        Operation = 'DeleteValue'
        Name      = $Name
    } -Action {
        param($providerPath)

        $split = Split-AtlasRegistryProviderPath -ProviderPath $providerPath
        $key = $split.BaseKey.OpenSubKey($split.SubPath, $true)
        if ($null -eq $key) {
            return
        }

        try {
            # The second argument suppresses the missing-value exception.
            $key.DeleteValue($Name, $false)
        }
        finally {
            $key.Close()
        }
    }
}
