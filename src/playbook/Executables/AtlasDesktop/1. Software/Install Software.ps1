function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
    exit
}

& "$env:windir\AtlasModules\Scripts\wingetCheck.cmd"
if ($LASTEXITCODE -ne '0') {exit 1}

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

# Set the size of the form
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
$Label.Text = "Download and install software using WinGet:"
$Form.Controls.Add($Label)


# https://winget.run/pkg/eloston/ungoogled-chromium
init_item "Ungoogled Chromium" "eloston.ungoogled-chromium"

# https://winget.run/pkg/Mozilla/Firefox
init_item "Mozilla Firefox" "Mozilla.Firefox"

# https://winget.run/pkg/Brave/brave
init_item "Brave Browser" "Brave.Brave"

# https://winget.run/pkg/Google/Chrome
init_item "Google Chrome" "Google.Chrome"

# https://winget.run/pkg/Microsoft/Edge
init_item "Microsoft Edge" "Microsoft.Edge"

# https://winget.run/pkg/LibreWolf/LibreWolf
init_item "LibreWolf" "LibreWolf.LibreWolf"

# https://winget.run/pkg/TorProject/TorBrowser
init_item "Tor Browser" "TorProject.TorBrowser"

# https://winget.run/pkg/Discord.Discord
init_item "Discord" "Discord.Discord"

# https://winget.run/pkg/Discord/Discord.Canary
init_item "Discord Canary" "Discord.Discord.Canary"

# https://winget.run/pkg/Valve/Steam
init_item "Steam" "Valve.Steam"

# https://winget.run/pkg/Playnite/Playnite
init_item "Playnite" "Playnite.Playnite"

# https://winget.run/pkg/HeroicGamesLauncher/HeroicGamesLauncher
init_item "Heroic" "HeroicGamesLauncher.HeroicGamesLauncher"

# https://winget.run/pkg/voidtools/Everything
init_item "Everything" "voidtools.Everything"

# https://winget.run/pkg/Mozilla/Thunderbird
init_item "Mozilla Thunderbird" "Mozilla.Thunderbird"

# https://winget.run/pkg/PeterPawlowski/foobar2000
init_item "foobar2000" "PeterPawlowski.foobar2000"

# https://winget.run/pkg/IrfanSkiljan/IrfanView
init_item "IrfanView" "IrfanSkiljan.IrfanView"

# https://winget.run/pkg/Git/Git
init_item "Git" "Git.Git"

# https://winget.run/pkg/VideoLAN/VLC
init_item "VLC" "VideoLAN.VLC"

# https://winget.run/pkg/PuTTY/PuTTY
init_item "PuTTY" "PuTTY.PuTTY"

# https://winget.run/pkg/Ditto/Ditto
init_item "Ditto" "Ditto.Ditto"

# https://winget.run/pkg/7zip/7zip
init_item "7-Zip" "7zip.7zip"

# https://winget.run/pkg/TeamSpeakSystems/TeamSpeakClient
init_item "Teamspeak" "TeamSpeakSystems.TeamSpeakClient"

# https://winget.run/pkg/Spotify/Spotify
init_item "Spotify" "Spotify.Spotify"

# https://winget.run/pkg/OBSProject/OBSStudio
init_item "OBS Studio" "OBSProject.OBSStudio"

# https://winget.run/pkg/Guru3D/Afterburner
init_item "MSI Afterburner" "Guru3D.Afterburner"

# https://winget.run/pkg/CPUID/CPU-Z
init_item "CPU-Z" "CPUID.CPU-Z"

# https://winget.run/pkg/TechPowerUp/GPU-Z
init_item "GPU-Z" "TechPowerUp.GPU-Z"

# https://winget.run/pkg/Notepad++/Notepad++
init_item "Notepad++" "Notepad++.Notepad++"

# https://winget.run/pkg/Microsoft/VisualStudioCode
init_item "VSCode" "Microsoft.VisualStudioCode"

# https://winget.run/pkg/VSCodium/VSCodium
init_item "VSCodium" "VSCodium.VSCodium"

# https://winget.run/pkg/Klocman/BulkCrapUninstaller
init_item "BCUninstaller" "Klocman.BulkCrapUninstaller"

# https://winget.run/pkg/REALiX/HWiNFO
init_item "HWiNFO" "REALiX.HWiNFO"

# https://winget.run/pkg/Skillbrains/Lightshot
init_item "Lightshot" "Skillbrains.Lightshot"

# https://winget.run/pkg/ShareX/ShareX
init_item "ShareX" "ShareX.ShareX"

$global:item_count = $global:items.Length

# Getting the index for splitting into two columns
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
$ToggleBtn.Add_Click({
if ($this.Text -eq "Dark Mode") {
    $this.Text = "Light Mode"
    dark_mode
} else {
    $this.Text = "Dark Mode"
    light_mode
}
})
# Changed into functions
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
    $Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $Form.ForeColor = [System.Drawing.Color]::Black
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
            $control.ForeColor = [System.Drawing.Color]::Black
        }
    }
}
# Checks the system "app" color (light or dark)
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize\"
$keyName = "AppsUseLightTheme"
function check_system_theme{
    if(((Get-ItemProperty -Path $registryPath -Name $keyName).$keyName) -eq 0){
        dark_mode
        $ToggleBtn.Text = "Light Mode"
    }
    else{
        light_mode
        $ToggleBtn.Text = "Dark Mode"
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
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Checkbox] } | ForEach-Object {
        if ($_.Checked) {
            [void]$installPackages.Add($_.Name)
        }
    }

    if ($installPackages.count -ne 0) {
        Write-Host "Installing: " -ForegroundColor Yellow
        foreach ($a in $installPackages) {
            Write-Host "- " -NoNewline -ForegroundColor Blue
            Write-Host "$a"
        }
        Write-Host ""
        Start-Sleep 1
        foreach ($package in $installPackages) {
            & winget install -e --id $package --accept-package-agreements --accept-source-agreements --disable-interactivity --force -h
        }
        Write-Host ""
        pause
    }
}
