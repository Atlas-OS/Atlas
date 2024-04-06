# --------------------------------------------------------------
# Remove ads from the 'Accounts' page in Immersive Control Panel
# --------------------------------------------------------------

# Find feature/velocity IDs to disable for the 'Accounts' page
# After disabling each one, there's a 'Microsoft account' page that appears (ms-settings:account)
# It can be hidden by using SettingsPageVisibility

# Variables
$cbsPublic = "$([Environment]::GetFolderPath('Windows'))\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Public"
$settingsExtensions = "$cbsPublic\wsxpacks\Account\SettingsExtensions.json"
if (!(Test-Path $settingsExtensions)) {
    Write-Output "Settings extensions ($settingsExtensions) not found."
    Write-Output "User is likely on Windows 10, nothing to do. Exiting..."
    exit
}

# Finds velocity IDs listed in 'Accounts' wsxpack
function Find-VelocityID($Node) {
    $ids = @()
    if ($Node -is [PSCustomObject]) {
        # If the node is a PSObject, go through through its properties
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -eq 'velocityKey' -and $property.Value.id) {
                $ids += $property.Value.id
            }
            Find-VelocityID -Node $property.Value
        }
    } elseif ($Node -is [Array]) {
        # If the node is an array, go through its elements
        foreach ($element in $Node) {
            Find-VelocityID -Node $element
        }
    }

    return $ids
}
$ids = Find-VelocityID -Node $(Get-Content -Path $settingsExtensions | ConvertFrom-Json)

# No IDs check
if ($ids.Count -le 0) {
    Write-Output "No velocity IDs were found, Microsoft might have changed something."
    exit 1
}

# Hide 'Microsoft account' page in Settings that appears
# Not set in the actual YAML in case no velocity IDs were found
# If the velocity IDs aren't set, then the account page disappears
function SettingsPageVisibility {
    $policyKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $visbility = "SettingsPageVisibility"
    $currentPolicy = (Get-ItemProperty -Path $policyKey -Name $visbility -EA 0).$visbility

    if ($currentPolicy -like "showonly:*") {
        return "Current $visibilityValue is 'showonly', no need to append."
    }

    $split = $currentPolicy -replace 'hide:' -split ';' | Where-Object { $_ }
    $split += "account"
    Set-ItemProperty -Path $policyKey -Name $visbility -Value "hide:$($split -join ';')"
}
SettingsPageVisibility

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
    Write-Output "Disabling velocity ID '$veloId'..."
    New-Item $veloId -Force | Out-Null
    Set-ItemProperty -Path $veloId -Name "EnabledStateOptions" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "EnabledState" -Value 1 -Force
    Set-ItemProperty -Path $veloId -Name "VariantPayload" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "Variant" -Value 0 -Force
    Set-ItemProperty -Path $veloId -Name "VariantPayloadKind" -Value 0 -Force
}