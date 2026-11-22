<#
.SYNOPSIS
    Removes the ads from the Accounts page in Settings.
.DESCRIPTION
    Finds the feature (velocity) IDs that the Accounts page's wsxpack lists in its
    SettingsExtensions.json, disables each one with the bundled ViVeTool, and hides the
    'Microsoft account' page (ms-settings:account) that Settings shows once they're
    disabled. The changes take effect from the next restart.

    The install's 'Modify Client.CBS' tweak runs it as TrustedInstaller in a child
    Windows PowerShell, and ignores its exit code: the wsxpack layout varies with the
    servicing state, and the change is cosmetic.
.NOTES
    Exit codes:
    0  The feature IDs were disabled.
    1  No SettingsExtensions.json or feature IDs were found, the page couldn't be hidden,
       or ViVeTool is missing.
#>

$windir = [Environment]::GetFolderPath('Windows')
$settingsExtensions = (Get-ChildItem "$windir\SystemApps" -Recurse).FullName | Where-Object { $_ -like '*wsxpacks\Account\SettingsExtensions.json*' }
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
if ($settingsExtensions.Count -eq 0) {
    Write-Error "No Account wsxpack SettingsExtensions.json was found under '$windir\SystemApps'; the Accounts-page ads cannot be disabled."
    exit 1
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

# Disabling the velocity IDs makes Settings show a separate 'Microsoft account' page.
# It's hidden here rather than in the tweak definition, because without disabled IDs
# that page isn't there to hide.
& "$windir\AtlasModules\Scripts\Entry\Set-SettingsPageVisibilityLauncher.cmd" /hide account
if ($LASTEXITCODE -ne 0) {
    throw "Hiding the Microsoft account Settings page failed with exit code $LASTEXITCODE."
}

# Extract ViVeTool https://github.com/thebookisclosed/ViVe
# Use ViVeTool to configure Windows feature IDs.
$viveZip = Get-ChildItem -Path "$windir\AtlasModules\Tools\ViVeTool-*.zip" -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
if ($arm) {
    $viveZip = $viveZip | Where-Object { $_ -match '-ARM64CLR' }
} else {
    $viveZip = $viveZip | Where-Object { $_ -notmatch '-ARM64CLR' }
}

# Extract and set up ViVeTool
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

# Feature configuration changes take effect from the next restart.
foreach ($id in $($ids | Sort-Object -Unique)) {
    Write-Output "Disabling feature ID $id..."
    ViVeTool.exe /disable /id:$id | Out-Null
}
