# Load DefaultUser hive
$module = Get-Module -Name "FXPSYaml"
if (!$module) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name FXPSYaml -Force
    Import-Module -Name FXPSYaml
}
reg load "HKU\AME_UserHive_Default" "C:\Users\Default\NTUSER.DAT"

$configurationFolder = Join-Path $PSScriptRoot "..\Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse
$mountPoint = "HKU\AME_UserHive_Default"
$RegistryPaths = @()
foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content $yamlFile.FullName -Raw
    $parsedYaml = ConvertFrom-Yaml $yamlContent
    foreach ($entry in $parsedYaml) {
        foreach ($value in $entry.actions.path) {
            if ($value -like 'HKU\AME_UserHive_Default*' -and $value -notlike 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce') {
                if (!$RegistryPaths.Contains($value.Substring(25))) { $RegistryPaths += $value.Substring(25) }
            }
        }
    }
}

foreach ($path in $RegistryPaths) {
    $source = "Registry::$mountPoint\$path"
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
reg unload "HKU\AME_UserHive_Default"