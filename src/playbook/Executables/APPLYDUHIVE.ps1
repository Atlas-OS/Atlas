# Load DefaultUser hive
$moduleName = 'FXPSYaml'
$minimumNuGetVersion = [Version]'2.8.5.201'
$loadedModule = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
if (-not $loadedModule) {
    $imported = $false
    try {
        Import-Module -Name $moduleName -ErrorAction Stop
        $imported = $true
    }
    catch {
        $nugetProvider = Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue
        if (-not $nugetProvider -or ([Version]$nugetProvider.Version) -lt $minimumNuGetVersion) {
            Install-PackageProvider -Name NuGet -MinimumVersion $minimumNuGetVersion -Force
        }

        $availableModule = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $availableModule) {
            Install-Module -Name $moduleName -Force
        }

        Import-Module -Name $moduleName -ErrorAction Stop
        $imported = $true
    }

    if (-not $imported) {
        throw "Unable to load required module '$moduleName'."
    }
}

$configurationFolder = Join-Path $PSScriptRoot "..\Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse -File
$registryPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content -LiteralPath $yamlFile.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($yamlContent)) { continue }
    # ignore YAML files without any HKCU references to avoid unnecessary parsing overhead
    if (-not [System.Text.RegularExpressions.Regex]::IsMatch($yamlContent, 'hkcu', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) { continue }

    $parsedYaml = $yamlContent | ConvertFrom-Yaml
    if (-not $parsedYaml) { continue }

    foreach ($entry in @($parsedYaml)) {
        if (-not $entry) { continue }

        $actions = @($entry.actions)
        if (-not $actions) { continue }

        foreach ($action in $actions) {
            if (-not $action) { continue }
            if (-not $action.PSObject.Properties['path']) { continue }

            foreach ($value in @($action.path)) {
                if ([string]::IsNullOrEmpty($value)) { continue }
                if ($value -like 'HKCU*') {
                    $null = $registryPaths.Add($value.Substring(4))
                }
            }
        }
    }
}

$metadataPropertyNames = @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')
$nameComparer = [System.StringComparer]::OrdinalIgnoreCase

foreach ($path in $registryPaths) {
    $source = "Registry::HKCU\$path"
    $destination = "Registry::HKU\AME_UserHive_Default\$path"
    $values = Get-ItemProperty -LiteralPath $source -ErrorAction SilentlyContinue
    if (-not $values) { continue }

    $destinationPropertyNames = [System.Collections.Generic.HashSet[string]]::new($nameComparer)
    if (Test-Path -LiteralPath $destination) {
        $existingProperties = Get-ItemProperty -LiteralPath $destination -ErrorAction SilentlyContinue
        if ($existingProperties) {
            $destinationPropertyNames.UnionWith($existingProperties.PSObject.Properties.Name)
        }
    }
    else {
        New-Item -Path $destination -Force | Out-Null
    }

    foreach ($property in $values.PSObject.Properties) {
        if ($metadataPropertyNames -contains $property.Name) { continue }

        if (-not $destinationPropertyNames.Contains($property.Name)) {
            New-ItemProperty -LiteralPath $destination -Name $property.Name -Value $property.Value | Out-Null
            [void]$destinationPropertyNames.Add($property.Name)
        }
        else {
            Set-ItemProperty -LiteralPath $destination -Name $property.Name -Value $property.Value
        }
    }
}
