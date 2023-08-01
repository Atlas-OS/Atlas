# Credit to spddl for part of the code 
# Require admin privileges if User Account Control (UAC) is enabled
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = 'SilentlyContinue'


[int] $global:column = 0
[int] $separate = 30
[int] $global:lastPos = 50
[int] $global:item_count = 0
[int] $global:index = 0
[array] $global:items = @()
[bool] $global:install = $false


function init_item{
    param(
        [string]$checkboxText,
        [string]$package
    )
    $global:items += , @($checkboxText, $package)
}
function generate_checkbox {
    param(
        [string]$checkboxText,
        [string]$package,
        [bool]$enabled = $true
    )
    $checkbox = new-object System.Windows.Forms.checkbox
    if($global:index -eq [math]::Ceiling($global:item_count / 2)){
        $global:column = 1
        $global:lastPos = 50
    }
    if($global:column -eq 0){
        $checkbox.Location = new-object System.Drawing.Size(30, $global:lastPos)
    }
    else{
        $checkbox.Location = new-object System.Drawing.Size(($global:column * 300), $global:lastPos)
    }
    $global:lastPos += $separate
    $checkbox.Size = new-object System.Drawing.Size(250, 18)
    $checkbox.Text = $checkboxText
    $checkbox.Name = $package
    $checkbox.Enabled = $enabled
    
    $checkbox
}

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Set the size of your form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Install Software | Atlas" # Titlebar
$Form.ShowIcon = $false
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.Size = New-Object System.Drawing.Size(600, 210)
$Form.AutoSizeMode = 0
$Form.KeyPreview = $True
$Form.SizeGripStyle = 2

# Label
$Label = New-Object System.Windows.Forms.label
$Label.Location = New-Object System.Drawing.Size(11, 15)
$Label.Size = New-Object System.Drawing.Size(255, 15)
$Label.Text = "Download and install software using Chocolatey:"
$Form.Controls.Add($Label)


# https://community.chocolatey.org/packages/ungoogled-chromium
init_item "ungoogled-chromium" "ungoogled-chromium"

# https://community.chocolatey.org/packages/Firefox
init_item "Mozilla Firefox" "firefox"

# https://community.chocolatey.org/packages/brave
init_item "Brave Browser" "brave"

# https://community.chocolatey.org/packages/GoogleChrome
init_item "Google Chrome" "googlechrome"

# https://community.chocolatey.org/packages/librewolf
init_item "LibreWolf" "librewolf"

# https://community.chocolatey.org/packages/tor-browser
init_item "Tor Browser" "tor-browser"

# https://community.chocolatey.org/packages/discord
init_item "Discord" "discord"

# https://community.chocolatey.org/packages/discord-canary
init_item "Discord Canary" "discord-canary"

# https://community.chocolatey.org/packages/steam
init_item "Steam" "steam"

# https://community.chocolatey.org/packages/playnite
init_item "Playnite" "playnite"

# https://community.chocolatey.org/packages/legendary
init_item "legendary" "legendary"

# https://community.chocolatey.org/packages/Everything
init_item "Everything" "everything"

# https://community.chocolatey.org/packages/thunderbird
init_item "Mozilla Thunderbird" "thunderbird"

# https://community.chocolatey.org/packages/foobar2000
init_item "foobar2000" "foobar2000"

# https://community.chocolatey.org/packages/irfanview
init_item "IrfanView" "irfanview"

# https://community.chocolatey.org/packages/git
init_item "Git" "git"

# https://community.chocolatey.org/packages/mpv
init_item "mpv" "mpv"

# https://community.chocolatey.org/packages/vlc
init_item "VLC" "vlc"

# https://community.chocolatey.org/packages/putty
init_item "PuTTY" "putty"

# https://community.chocolatey.org/packages/ditto
init_item "Ditto" "ditto"

# https://community.chocolatey.org/packages/7zip
init_item "7-Zip" "7zip"

# https://community.chocolatey.org/packages/teamspeak
init_item "Teamspeak" "teamspeak"

# https://community.chocolatey.org/packages/spotify
init_item "Spotify" "spotify"

# https://community.chocolatey.org/packages/obs-studio
init_item "OBS Studio" "obs-studio"

# https://community.chocolatey.org/packages/msiafterburner
init_item "MSI Afterburner" "msiafterburner"

# https://community.chocolatey.org/packages/cpu-z
init_item "CPU-Z" "cpu-z"

# https://community.chocolatey.org/packages/gpu-z
init_item "GPU-Z" "gpu-z"

# https://community.chocolatey.org/packages/notepadplusplus
init_item "Notepad++" "notepadplusplus"

# https://community.chocolatey.org/packages/vscode
init_item "VSCode" "vscode"

# https://community.chocolatey.org/packages/bulk-crap-uninstaller
init_item "Bulk Crap Uninstaller" "bulk-crap-uninstaller"

# https://community.chocolatey.org/packages/hwinfo
init_item "HWiNFO" "hwinfo"

# https://community.chocolatey.org/packages/lightshot
init_item "Lightshot" "lightshot"


$global:item_count = $global:items.Length

foreach($item in $global:items){
    if($global:index -eq ($global:item_count / 2)){
        $global:column = 1
    }
    $Form.Controls.Add((generate_checkbox $item[0] $item[1]))
    $global:index ++
}

if ($global:column -ne 0) {
    $global:lastPos += $separate
}

$Form.height = $global:lastPos + 80

# Dark Mode/Light Mode Toggle
$ToggleBtn = New-Object System.Windows.Forms.Button
$ToggleBtn.Location = New-Object System.Drawing.Point(500, 20)
$ToggleBtn.Size = New-Object System.Drawing.Size(80, 23)
$ToggleBtn.Text = "Dark Mode"
$ToggleBtn.Add_Click({
if ($this.Text -eq "Dark Mode") {
    $this.Text = "Light Mode"
    dark_mode
} else {
    $this.Text = "Dark Mode"
    light_mode
}
})
function dark_mode {
    $Form.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
    $Form.ForeColor = [System.Drawing.Color]::White
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
            $control.ForeColor = [System.Drawing.Color]::White
        }
    }
}
function light_mode {
    $Form.BackColor = [System.Drawing.Color]::White
    $Form.ForeColor = [System.Drawing.Color]::Black
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::White
            $control.ForeColor = [System.Drawing.Color]::Black
        }
    }
}
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\"
$keyName = "AppsUseLightTheme"
function check_system_theme{
    if(((Get-ItemProperty -Path $registryPath -Name $keyName).$keyName) -eq 0){
        dark_mode
    }
}
check_system_theme

$Form.Controls.Add($ToggleBtn)

# Install Button
$lastPosWidth = $form.Width - 80 - 31
$InstallButton = new-object System.Windows.Forms.Button
$InstallButton.Location = new-object System.Drawing.Size($lastPosWidth, $global:lastPos)
$InstallButton.Size = new-object System.Drawing.Size(80, 23)
$InstallButton.Text = "Install"
$InstallButton.Add_Click({
    $checkedBoxes = $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Checkbox] -and $_.Checked }
    if ($checkedBoxes.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one software package to install.", "No package selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    else {
        $global:install = $true
        $Form.Close()
    }
})
$Form.Controls.Add($InstallButton)

# Activate the form
$Form.Add_Shown({ $Form.Activate() })
[void] $Form.ShowDialog()

if ($global:install) {
    $installPackages = [System.Collections.ArrayList]::new()
    $installSeparatedPackages = [System.Collections.ArrayList]::new()
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Checkbox] } | ForEach-Object {
        if ($_.Checked) {
            if ($_.Name.contains("--")) {
                [void]$installSeparatedPackages.Add($_.Name)
            }
            else {
                [void]$installPackages.Add($_.Name)
            }
        }
    }

    if ($installPackages.count -ne 0) {
        Write-Host "$Env:ProgramData\chocolatey\choco.exe install $($installPackages -join ' ') -y"
        Start-Process -FilePath "$Env:ProgramData\chocolatey\choco.exe" -ArgumentList "install $($installPackages -join ' ') -y --ignore-checksums" -Wait
    }
    if ($installSeparatedPackages.count -ne 0) {
        foreach ($paket in $installSeparatedPackages) {
            Write-Host "$Env:ProgramData\chocolatey\choco.exe install $paket -y"
            Start-Process -FilePath "$Env:ProgramData\chocolatey\choco.exe" -ArgumentList "install $paket -y --ignore-checksums" -Wait
            if ($paket.contains("--version")) {
                Write-Host "$Env:ProgramData\chocolatey\choco.exe pin add -n $($paket.split(' ')[0])"
                Start-Process -FilePath "$Env:ProgramData\chocolatey\choco.exe" -ArgumentList "pin add -n $($paket.split(' ')[0])" -Wait
            }
        }
    }
}
