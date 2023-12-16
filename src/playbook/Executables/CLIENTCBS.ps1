$cbsPublic = "$env:windir\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Public"

# Remove ads from the 'Accounts' page in Immersive Control Panel
# --------------------------------------------------------------

# Find feature/velocity IDs to disable for the 'Accounts' page
# After disabling each one, there's a 'Microsoft account' page that appears (ms-settings:account)
# It can be hidden by using SettingsPageVisibility

# Finds velocity IDs listed in 'Accounts' wsxpack
$ids = @()
function Find-VelocityID($Node) {
    if ($Node -is [PSCustomObject]) {
        # If the node is a PSObject, go through through its properties
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -eq 'velocityKey' -and $property.Value.id) {
                $global:ids += $property.Value.id
            }
            Find-VelocityID -Node $property.Value
        }
    } elseif ($Node -is [Array]) {
        # If the node is an array, go through its elements
        foreach ($element in $Node) {
            Find-VelocityID -Node $element
        }
    }
}
Find-VelocityID -Node $(Get-Content -Path "$cbsPublic\wsxpacks\Account\SettingsExtensions.json" | ConvertFrom-Json)

# Obfuscate velocity IDs
# Rewritten in PowerShell from ViVE
# https://github.com/thebookisclosed/ViVe/blob/master/ViVe/ObfuscationHelpers.cs
class ObfuscationHelpers {
    static [uint32] SwapBytes([uint32] $x) {
        $x = ($x -shr 16) -bor ($x -shl 16)
        return (($x -band 0xFF00FF00) -shr 8) -bor (($x -band 0x00FF00FF) -shl 8)
    }

    static [uint32] RotateRight32([uint32] $value, [int] $shift) {
        return ($value -shr $shift) -bor ($value -shl (32 - $shift))
    }

    static [uint32] ObfuscateFeatureId([uint32] $featureId) {
        return [ObfuscationHelpers]::RotateRight32(([ObfuscationHelpers]::SwapBytes($featureId -bxor 0x74161A4E) -bxor 0x8FB23D4F), -1) -bxor 0x833EA8FF
    }

    static [uint32] DeobfuscateFeatureId([uint32] $featureId) {
        return [ObfuscationHelpers]::SwapBytes(([ObfuscationHelpers]::RotateRight32($featureId -bxor 0x833EA8FF, 1) -bxor 0x8FB23D4F)) -bxor 0x74161A4E
    }
}

# Disable velocity IDs
# Applies next reboot
$featureKey = "HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8"
foreach ($id in $($ids | Sort-Object -Unique)) {
    $veloId = "$featureKey\$([ObfuscationHelpers]::ObfuscateFeatureId($id))"
    Write-Host "Disabling velocity ID '$veloId'..."
    New-Item $veloId -Force | Out-Null
    Set-ItemProperty -Path $veloId -Name "EnabledStateOptions" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "EnabledState" -Value 1 -Force
    Set-ItemProperty -Path $veloId -Name "VariantPayload" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "Variant" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "VariantPayloadKind" -Value 0 -Force
}