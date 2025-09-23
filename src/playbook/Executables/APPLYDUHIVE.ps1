# Load DefaultUser hive
$module = Get-Module -Name "FXPSYaml"
if (!$module) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name FXPSYaml -Force
    Import-Module -Name FXPSYaml
}
$mountPoint = "Registry::HKU\.DEFAULT"

$configurationFolder = Join-Path $PSScriptRoot "..\Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse

$RegistryPaths = @()
foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content $yamlFile.FullName -Raw
    $parsedYaml = ConvertFrom-Yaml $yamlContent
    foreach ($entry in $parsedYaml) {
        foreach ($value in $entry.actions.path) {
            if ($value -like 'HKU\.DEFAULT*') {
                if (!$RegistryPaths.Contains($value.Substring(13))) { $RegistryPaths += $value.Substring(13) }
            }
        }
    }
}

foreach ($path in $RegistryPaths) {
    $source = "$mountPoint\$path"
    $destination = "Registry::HKCU\$path"
    $values = Get-ItemProperty -Path $source -ErrorAction SilentlyContinue
    if ($values) {
        foreach ($property in $values.PSObject.Properties) {
            if ($property.Name -ne "PSPath" -and $property.Name -ne "PSParentPath" -and $property.Name -ne "PSChildName" -and $property.Name -ne "PSDrive" -and $property.Name -ne "PSProvider") {
                if (-not (Test-Path $destination)) {
                    New-Item -Path $destination -Force | Out-Null
                }
                if (-not ((Get-ItemProperty $destination -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains $property.Name)) {
                    New-ItemProperty -Path $destination -Name $property.Name -Value $property.Value | Out-Null
                }
                else {
                    Set-ItemProperty -Path $destination -Name $property.Name -Value $property.Value
                }
            }
        }
    }
}
Remove-Module "FXPSYaml" -Force
# Unload DefaultUser hive
reg unload $mountPoint