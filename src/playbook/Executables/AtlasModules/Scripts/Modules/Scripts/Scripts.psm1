# ==============================
# PowerShell Module for Executing System Scripts
# ==============================

# Backup Atlas Services and Drivers
$windir = $([Environment]::GetFolderPath('Windows'))
function Backup-AtlasServices {
$filePath = "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Other\atlasServices.reg"
if (Test-Path $FilePath) { exit }

$content = [System.Collections.Generic.List[string]]::new()
$content.Add("Windows Registry Editor Version 5.00")
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
	try {
		$values = Get-ItemProperty -Path $_.PSPath -Name 'Start', 'Description' -EA Stop
		if ($values.Description -notmatch 'Windows Defender') {
			$content.Add("`n[$($_.Name)]")
			$content.Add('"Start"=dword:0000000' + $values.Start)	
		} else {
			Write-Output "Excluding $($_.Name)..."
		}
	} catch {}
}

# Set-Content can only do UTF8 with BOM, which doesn't work with reg.exe
[System.IO.File]::WriteAllLines($FilePath, $content, (New-Object System.Text.UTF8Encoding $false))
}

# Modify Client.CBS components
function Update-ClientCBS {
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
}

# Disable Core Isolation (VBS)
function Disable-CoreIsolation {
    & ".\AtlasModules\Scripts\ScriptWrappers\ConfigVBS.ps1" -DisableAllVBS
}

# Disable Unneeded Devices
function Disable-Devices {
    Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr
    # Disable PnP (plug and play) devices
    $devices = @(
    	"AMD PSP",
    	"AMD SMBus",
    	"Base System Device",
    	"Composite Bus Enumerator",
    	"Direct memory access controller"
    	"High precision event timer",
    	"Intel Management Engine",
    	"Intel SMBus",
    	"Legacy device",
    	"Microsoft Kernel Debug Network Adapter",
    	"Motherboard resources",
    	"Numeric Data Processor",
    	"PCI Data Acquisition and Signal Processing Controller",
    	"PCI Encryption/Decryption Controller",
    	"PCI Memory Controller",
    	"PCI Simple Communications Controller",
    	"PCI standard RAM Controller",
    	"SM Bus Controller",
    	"System CMOS/real time clock",
    	"System Speaker",
    	"System Timer"
    )
    
    # No errors as some devices may not have an option to be disabled
    Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore | Disable-PnpDevice -Confirm:$false -ErrorAction Ignore

}

# Set File Associations for Web Browsers and Other Apps
function Set-FileAssociations {
    param (
        [string]$Browser
    )

    # Uninstall Edge (if applicable)
    Start-Process -FilePath ".\fileAssoc.cmd" -NoNewWindow -Wait
    
    # Set default browser
    if ($Browser -in @("Brave", "LibreWolf", "Firefox", "Google Chrome")) {
        Start-Process -FilePath ".\fileAssoc.cmd" -ArgumentList "`"$Browser`"" -NoNewWindow -Wait
    }
}

# Disable Mitigations
function Disable-Mitigations {
    Start-Process -FilePath "AtlasDesktop\7. Security\Mitigations\Disable All Mitigations.cmd" -ArgumentList "/silent" -NoNewWindow -Wait
}

# Runs NGEN on PowerShell Libraries
function Optimize-PowerShellStartup {
    # speeds up powershell startup time by 10x
    $env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
    [AppDomain]::CurrentDomain.GetAssemblies().Location | ? {$_} | % {
        Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
        ngen install $_ | Out-Null
    }
}

# Set Atlas Default Profile Pictures
function Set-ProfilePictures {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile((Get-Item '.\user.png'))
    
    $resolutions = @{
        "user.png" = 448
        "user.bmp" = 448
        "guest.png" = 448
        "guest.bmp" = 448
        "user-192.png" = 192
        "user-48.png" = 48
        "user-40.png" = 40
        "user-32.png" = 32
    }
    
    # Set default profile pictures
    foreach ($image in $resolutions.Keys) {
        $resolution = $resolutions[$image]
    
        $a = New-Object System.Drawing.Bitmap($resolution, $resolution)
        $graph = [System.Drawing.Graphics]::FromImage($a)
        $graph.DrawImage($img, 0, 0, $resolution, $resolution)
        $a.Save("$([Environment]::GetFolderPath('CommonApplicationData'))\Microsoft\User Account Pictures\$image")
    }
}

# Configure Power Settings
function Set-PowerSettings {
    param (
        [switch]$DisablePowerSaving,
        [switch]$DisableHibernation
    )

    if ($DisablePowerSaving) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Power-saving\Disable Power-saving.cmd" -ArgumentList "/silent" -NoNewWindow -Wait
    }

    if ($DisableHibernation) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Hibernation\Disable Hibernation (default).cmd" -ArgumentList "/silent" -NoNewWindow -Wait
    }

    if (-not $DisablePowerSaving) {
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive `"381b4222-f694-41f0-9685-ff5bb260df2e`"" -NoNewWindow -Wait
    }
}

function Invoke-AllSystemScripts {
    Write-Host "Running scripts"
    Backup-AtlasServices
    Update-ClientCBS
    Disable-CoreIsolation
    Disable-Devices
    Set-FileAssociations -Browser "default"
    Disable-Mitigations
    Optimize-PowerShellStartup
    Set-ProfilePictures
    Set-PowerSettings -DisablePowerSaving -DisableHibernation
}

Export-ModuleMember -Function Invoke-AllSystemScripts