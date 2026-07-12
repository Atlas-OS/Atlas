# --------------------------------------------------------------
# Remove ads from the 'Accounts' page in Immersive Control Panel
# --------------------------------------------------------------

# Find feature/velocity IDs to disable for the 'Accounts' page
# After disabling each one, there's a 'Microsoft account' page that appears (ms-settings:account)
# It can be hidden by using SettingsPageVisibility

$windir = [Environment]::GetFolderPath('Windows')
$settingsExtensions = (Get-ChildItem "$windir\SystemApps" -Recurse).FullName | Where-Object { $_ -like '*wsxpacks\Account\SettingsExtensions.json*' }
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
if ($settingsExtensions.Count -eq 0) {
    Write-Output "Settings extensions ($settingsExtensions) not found."
    Write-Output "User is likely on Windows 10, nothing to do. Exiting..."
    exit
}

# Finds velocity IDs listed in 'Accounts' wsxpack
function Find-VelocityID {
    param (
        $Node
    )

    $ids = @()
    if ($Node -is [PSCustomObject]) {
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -eq 'velocityKey' -and $property.Value.id) {
                $ids += $property.Value.id
            }
            # Capture the recursion result explicitly instead of letting it leak
            # onto the pipeline.
            $ids += Find-VelocityID -Node $property.Value
        }
    } elseif ($Node -is [Array]) {
        foreach ($element in $Node) {
            $ids += Find-VelocityID -Node $element
        }
    }

    return $ids
}

$ids = @()
foreach ($settingsJson in $settingsExtensions) {
    $ids += Find-VelocityID -Node $(Get-Content -Path $settingsJson | ConvertFrom-Json)
}

if ($ids.Count -le 0) {
    Write-Output "No velocity IDs were found. Exiting."
    exit 1
}

# Hide 'Microsoft account' page in Settings that appears
# Not set in the actual YAML in case no velocity IDs were found
# If the velocity IDs aren't set, then the account page disappears
& "$windir\AtlasModules\Scripts\Set-SettingsPageVisibilityLauncher.cmd" /hide account
if ($LASTEXITCODE -ne 0) {
    throw "Hiding the Microsoft account Settings page failed with exit code $LASTEXITCODE."
}

# Extract ViVeTool https://github.com/thebookisclosed/ViVe
# Not done in PowerShell as it's too complicated, it's just easiest to use the actual tool
$viveZip = Get-ChildItem -Path "$windir\AtlasModules\Tools\ViVeTool-*.zip" -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
if ($arm) {
    $viveZip = $viveZip | Where-Object { $_ -match '-ARM64CLR' }
} else {
    $viveZip = $viveZip | Where-Object { $_ -notmatch '-ARM64CLR' }
}

# Extract & setup ViVeTool
if ($viveZip) {
    $viveFolder = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "AtlasViVeTool"
    if (Test-Path -Path $viveFolder) {
        Remove-Item -Path $viveFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $viveFolder -Force | Out-Null
    Expand-Archive -Path $viveZip -DestinationPath $viveFolder -Force
} else {
    throw "ViVeTool not found!"
}
$env:PATH += ";$viveFolder"
if (!(Get-Command 'vivetool' -EA 0)) {
    throw "ViVeTool EXE not found in ZIP!"
}

# Applies next reboot
foreach ($id in $($ids | Sort-Object -Unique)) {
    Write-Output "Disabling feature ID $id..."
    ViVeTool.exe /disable /id:$id | Out-Null
}
