$configurationFolder = Join-Path $PSScriptRoot "..\Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse -File

$registryPaths = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$pathPattern = [regex]::new('^(?!\s*#).*?\bpath\s*:\s*[''\"]HKCU\\(?<path>[^''\"]+)[''\"]', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)

foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content -Path $yamlFile.FullName -Raw
    foreach ($match in $pathPattern.Matches($yamlContent)) {
        $relativePath = $match.Groups['path'].Value.Trim()
        if (![string]::IsNullOrWhiteSpace($relativePath)) {
            $null = $registryPaths.Add($relativePath)
        }
    }
}

if ($registryPaths.Count -eq 0) {
    Write-Warning "No HKCU registry paths were found in tweak YAML files."
    exit
}

foreach ($relativePath in ($registryPaths | Sort-Object)) {
    $sourceKey = $null
    $destinationKey = $null

    try {
        $sourceKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($relativePath, $false)
        if ($null -eq $sourceKey) {
            continue
        }

        $destinationKey = [Microsoft.Win32.Registry]::Users.CreateSubKey("AME_UserHive_Default\$relativePath")
        if ($null -eq $destinationKey) {
            Write-Warning "Failed to create destination key: HKU\\AME_UserHive_Default\\$relativePath"
            continue
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
