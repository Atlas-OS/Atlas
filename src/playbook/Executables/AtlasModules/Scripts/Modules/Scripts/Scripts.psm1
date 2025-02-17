# ==============================
# PowerShell Module for Executing System Scripts
# ==============================

# Backup Atlas Services and Drivers
function Backup-AtlasServices {
    .\BACKUP.ps1 -FilePath "$([Environment]::GetFolderPath('Windows'))\AtlasModules\Other\atlasServices.reg"
}

# Modify Client.CBS components
function Update-ClientCBS {
    .\CLIENTCBS.ps1
}

# Disable Core Isolation (VBS)
function Disable-CoreIsolation {
    & ".\AtlasModules\Scripts\ScriptWrappers\ConfigVBS.ps1" -DisableAllVBS
}

# Disable Unneeded Devices
function Disable-Devices {
    Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr
    .\DISABLEPNP.ps1
}

# Set File Associations for Web Browsers and Other Apps
function Set-FileAssociations {
    param (
        [string]$Browser
    )

    # Uninstall Edge (if applicable)
    Start-Process -FilePath "FILEASSOC.cmd" -NoNewWindow -Wait

    # Set default browser
    if ($Browser -in @("Brave", "LibreWolf", "Firefox", "Google Chrome")) {
        Start-Process -FilePath "FILEASSOC.cmd" -ArgumentList "`"$Browser`"" -NoNewWindow -Wait
    }
}

# Disable Mitigations
function Disable-Mitigations {
    Start-Process -FilePath "AtlasDesktop\7. Security\Mitigations\Disable All Mitigations.cmd" -ArgumentList "/silent" -NoNewWindow -Wait
}

# Runs NGEN on PowerShell Libraries
function Optimize-PowerShellStartup {
    .\NGEN.ps1
}

# Set Atlas Default Profile Pictures
function Set-ProfilePictures {
    .\PFP.ps1
}

# Configure Power Settings
function Set-PowerSettings {
    param (
        [switch]$DisablePowerSaving,
        [switch]$DisableHibernation
    )

    if ($DisablePowerSaving) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Power-saving\Disable Power-saving.cmd" -ArgumentList "-Silent" -NoNewWindow -Wait
    }

    if ($DisableHibernation) {
        Start-Process -FilePath "AtlasDesktop\3. General Configuration\Hibernation\Disable Hibernation (default).cmd" -ArgumentList "/silent" -NoNewWindow -Wait
    }

    if (-not $DisablePowerSaving) {
        Start-Process -FilePath "powercfg.exe" -ArgumentList "/setactive `"381b4222-f694-41f0-9685-ff5bb260df2e`"" -NoNewWindow -Wait
    }
}

function Invoke-AllSystemScripts {
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