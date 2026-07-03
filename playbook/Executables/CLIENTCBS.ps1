# --------------------------------------------------------------
# Remove ads from the 'Accounts' page in Immersive Control Panel
# --------------------------------------------------------------

# Find feature/velocity IDs to disable for the 'Accounts' page
# After disabling each one, there's a 'Microsoft account' page that appears (ms-settings:account)
# It can be hidden by using SettingsPageVisibility

# Variables
$windir = [Environment]::GetFolderPath('Windows')
$settingsExtensions = (Get-ChildItem "$windir\SystemApps" -Recurse).FullName | Where-Object { $_ -like '*wsxpacks\Account\SettingsExtensions.json*' }
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
if ($settingsExtensions.Count -eq 0) {
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
$ids = @()
foreach ($settingsJson in $settingsExtensions) {
    $ids += Find-VelocityID -Node $(Get-Content -Path $settingsJson | ConvertFrom-Json)
}

# No IDs check
if ($ids.Count -le 0) {
    Write-Output "No velocity IDs were found. Exiting."
    exit 1
}

# Hide 'Microsoft account' page in Settings that appears
# Not set in the actual YAML in case no velocity IDs were found
# If the velocity IDs aren't set, then the account page disappears
& "$windir\AtlasModules\Scripts\settingsPages.cmd" /hide account

# Extract ViVeTool https://github.com/thebookisclosed/ViVe
# Not done in PowerShell as it's too complicated, it's just easiest to use the actual tool
$viveZip = Get-ChildItem "ViVeTool-*.zip" -Name
if ($arm) {
    $viveZip = $viveZip | Where-Object { $_ -match '-ARM64CLR' }
} else {
    $viveZip = $viveZip | Where-Object { $_ -notmatch '-ARM64CLR' }
}

# Extract & setup ViVeTool
if ($viveZip) {
    $viveFolder = Join-Path -Path (Get-Location) -ChildPath "vivetool"
    if (!(Test-Path -Path $viveFolder)) {
        New-Item -ItemType Directory -Path $viveFolder | Out-Null
    }
    Expand-Archive -Path $viveZip -DestinationPath $viveFolder -Force
} else {
    throw "ViVeTool not found!"
}
$env:PATH += ";$viveFolder"
if (!(Get-Command 'vivetool' -EA 0)) {
    throw "ViVeTool EXE not found in ZIP!"
}

# Disable feature IDs
# Applies next reboot
foreach ($id in $($ids | Sort-Object -Unique)) {
    Write-Output "Disabling feature ID $id..."
    ViVeTool.exe /disable /id:$id | Out-Null
}