# Load YamlDotNet for YAML parsing
# YamlDotNet by Antoine Aubry - https://github.com/aaubry/YamlDotNet (MIT License)
Add-Type -Path "$PSScriptRoot\YamlDotNet.dll"

function ConvertFrom-Yaml {
    param([string]$YamlString)
    $reader = New-Object System.IO.StringReader($YamlString)
    $yamlStream = New-Object YamlDotNet.RepresentationModel.YamlStream
    $yamlStream.Load($reader)
    $reader.Close()

    function ConvertNode($node) {
        if ($node -is [YamlDotNet.RepresentationModel.YamlMappingNode]) {
            $ht = @{}
            foreach ($pair in $node.Children) {
                $ht[$pair.Key.Value] = ConvertNode $pair.Value
            }
            return $ht
        }
        elseif ($node -is [YamlDotNet.RepresentationModel.YamlSequenceNode]) {
            $arr = @()
            foreach ($item in $node.Children) {
                $arr += ConvertNode $item
            }
            return $arr
        }
        else {
            return $node.Value
        }
    }

    return ConvertNode $yamlStream.Documents[0].RootNode
}

$configurationFolder = Join-Path $PSScriptRoot "..\Configuration\tweaks"
$yamlFiles = Get-ChildItem -Path $configurationFolder -Filter *.yml -Recurse
$RegistryPaths = @()
foreach ($yamlFile in $yamlFiles) {
    $yamlContent = Get-Content $yamlFile.FullName -Raw
    $parsedYaml = ConvertFrom-Yaml $yamlContent
    foreach ($entry in $parsedYaml) {
        foreach ($value in $entry.actions.path) {
            if ($value -like 'HKCU') {
                if (!$RegistryPaths.Contains($value.Substring(4))) { $RegistryPaths += $value.Substring(4) }
            }
        }
    }
}

foreach ($path in $RegistryPaths) {
    $source = "Registry::HKCU\$path"
    $destination = "Registry::HKU\AME_UserHive_Default\$path"
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
