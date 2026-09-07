# Atlas.Registry domain: registry value writes and deletes.
#
# Windows protects a small number of policy values against every caller, including
# TrustedInstaller: the key opens for writing and the kernel then refuses the value.
# That refusal carries this error id so callers can tell it apart from an Atlas defect
# such as a mistyped path, and treat it as best effort where a definition says so.
#
# Values are written through the Microsoft.Win32.Registry API instead of the provider
# cmdlets so the value kind is always explicit (including REG_NONE, which the provider
# cannot round-trip) and so redirected HKEY_USERS paths behave identically to drives.

$script:AtlasRegistryValueRefusedErrorId = 'AtlasRegistryValueWriteRefused'

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

function New-AtlasRegistryValueRefusedRecord {
    <#
    .SYNOPSIS
        Builds the error record that marks a value write Windows itself refused, so
        callers can tell an operating-system protection apart from an Atlas defect.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProviderPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [Exception]$Cause
    )

    $displayName = if ([string]::IsNullOrEmpty($Name)) { '(default)' } else { $Name }
    $message = "Windows refused the value '$displayName' at '$ProviderPath'. The key itself opened for writing, so this value is protected by the operating system."
    return (New-Object System.Management.Automation.ErrorRecord(
            (New-Object System.UnauthorizedAccessException($message, $Cause)),
            $script:AtlasRegistryValueRefusedErrorId,
            [System.Management.Automation.ErrorCategory]::PermissionDenied,
            $ProviderPath))
}

function Test-AtlasRegistryValueRefused {
    <#
    .SYNOPSIS
        Returns $true when an error record is a refusal of a value write by Windows.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    return ([string]$ErrorRecord.FullyQualifiedErrorId -ceq $script:AtlasRegistryValueRefusedErrorId)
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
    catch [System.UnauthorizedAccessException] {
        # CreateSubKey above already proved write access to the key, so a denial here is
        # Windows refusing this particular value. No right Atlas can hold changes that.
        throw (New-AtlasRegistryValueRefusedRecord -ProviderPath $ProviderPath -Name $Name -Cause $_.Exception)
    }
    finally {
        $key.Close()
    }
}

function Set-AtlasRegistryValue {
    <#
    .SYNOPSIS
        Writes a registry value, creating missing keys. An empty Name writes the key's
        default value. HKCU is either the proven current token's ambient hive or the
        explicitly install-state-bound fixed default-user hive.
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

        [object]$Data,

        # Windows protects a small number of policy values against every caller. Where
        # that is expected, a refusal is a logged warning instead of a failure; the
        # Atlas health check still reports the value as drift.
        [switch]$AllowOsProtected
    )

    if ($null -eq $Data -and $Type -notin @('None', 'String', 'ExpandString')) {
        throw "Registry value '$Name' at '$Path' has type '$Type' but no data."
    }

    try {
        # The scriptblock resolves $Name/$Type/$Data dynamically from this function's scope.
        Invoke-AtlasRegistryTargetOperation -Path $Path -Action {
            param($providerPath)
            Set-AtlasRegistryValueCore -ProviderPath $providerPath -Name $Name -Type $Type -Data $Data
        }
    }
    catch {
        if ($AllowOsProtected -and (Test-AtlasRegistryValueRefused -ErrorRecord $_)) {
            Write-AtlasLog -Level Warning -Message "$($_.Exception.Message) Continuing without it." -ErrorRecord $_
            return
        }
        throw
    }
}

function Remove-AtlasRegistryValue {
    <#
    .SYNOPSIS
        Deletes a registry value if it exists (a missing key or value is not an error),
        with the same token/default-user scope binding as
        Set-AtlasRegistryValue.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        # See Set-AtlasRegistryValue: a value Windows protects is a warning, not a failure.
        [switch]$AllowOsProtected
    )

    try {
        Invoke-AtlasRegistryTargetOperation -Path $Path -Action {
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
            catch [System.UnauthorizedAccessException] {
                # The key opened for writing, so Windows is protecting this value.
                throw (New-AtlasRegistryValueRefusedRecord -ProviderPath $providerPath -Name $Name -Cause $_.Exception)
            }
            finally {
                $key.Close()
            }
        }
    }
    catch {
        if ($AllowOsProtected -and (Test-AtlasRegistryValueRefused -ErrorRecord $_)) {
            Write-AtlasLog -Level Warning -Message "$($_.Exception.Message) Continuing without removing it." -ErrorRecord $_
            return
        }
        throw
    }
}
