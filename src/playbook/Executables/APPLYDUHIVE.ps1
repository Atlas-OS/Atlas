# Load DefaultUser hive
$module = Get-Module -Name "PSYaml"
if (!$module) {
    Install-Module "FXPSYaml"
}
$defaultUserHive = "C:\Users\Default\NTUSER.DAT"
$mountPoint = "HKU\DefaultUserTemp"
reg load $mountPoint $defaultUserHive

# Parse YAML files in configuration folder to get HKCU registry paths
$configurationFolder = Join-Path $PSScriptRoot "Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse

$RegistryPaths = @()
foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content $yamlFile.FullName -Raw
    $parsedYaml = ConvertFrom-Yaml $yamlContent
    foreach ($entry in $parsedYaml) {
        foreach ($value in $entry.actions.path) {
            if ($value -like 'HKU\.DEFAULT*') {
                if (!$RegistryPaths.Contains($value)) { $RegistryPaths += $value.Substring(5) }
            }
        }
    }
}

foreach ($path in $RegistryPaths) {
    $source = "$mountPoint\$path"
    $destination = "HKCU\$path"
    # Copy all values from source to destination
    $values = Get-ItemProperty -Path $source -ErrorAction SilentlyContinue
    if ($values) {
        foreach ($property in $values.PSObject.Properties) {
            if ($property.Name -ne "PSPath" -and $property.Name -ne "PSParentPath" -and $property.Name -ne "PSChildName" -and $property.Name -ne "PSDrive" -and $property.Name -ne "PSProvider") {
                Set-ItemProperty -Path $destination -Name $property.Name -Value $property.Value
            }
        }
    }
}

# Unload DefaultUser hive
reg unload $mountPoint