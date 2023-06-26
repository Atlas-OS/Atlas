# Credit to spddl for part of the code
# Require admin privileges if User Account Control (UAC) is enabled
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = 'SilentlyContinue'

[int] $global:column = 0
[int] $maxColumn = 1
[int] $separate = 30
[int] $global:lastPos = 50
[bool]$global:install = $false

function generate_checkbox {
    param(
        [string]$checkboxText,
        [string]$package,
        [bool]$enabled = $true
    )
    $checkbox = new-object System.Windows.Forms.checkbox
    if ($global:column -ge $maxColumn) {
        $checkbox.Location = new-object System.Drawing.Size(($global:column * 300), $global:lastPos)
        $global:column = 0
        $global:lastPos += $separate
    }
    else {
        $checkbox.Location = new-object System.Drawing.Size(30, $global:lastPos)
        $global:column = $column + 1
    }
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

# https://community.chocolatey.org/packages/GoogleChrome
$Form.Controls.Add((generate_checkbox "Google Chrome" "googlechrome"))

# https://community.chocolatey.org/packages/Firefox
$Form.Controls.Add((generate_checkbox "Mozilla Firefox" "firefox"))

# https://community.chocolatey.org/packages/brave
$Form.Controls.Add((generate_checkbox "Brave Browser" "brave"))

# https://community.chocolatey.org/packages/microsoft-edge
$Form.Controls.Add((generate_checkbox "Microsoft Edge" "microsoft-edge"))

# https://community.chocolatey.org/packages/librewolf
$Form.Controls.Add((generate_checkbox "LibreWolf" "librewolf"))

# https://community.chocolatey.org/packages/ungoogled-chromium
$Form.Controls.Add((generate_checkbox "ungoogled-chromium" "ungoogled-chromium"))

# https://community.chocolatey.org/packages/discord
$Form.Controls.Add((generate_checkbox "Discord" "discord"))

# https://community.chocolatey.org/packages/discord-canary
$Form.Controls.Add((generate_checkbox "Discord Canary" "discord-canary"))

# https://community.chocolatey.org/packages/steam
$Form.Controls.Add((generate_checkbox "Steam" "steam"))

# https://community.chocolatey.org/packages/playnite
$Form.Controls.Add((generate_checkbox "Playnite" "playnite"))

# https://community.chocolatey.org/packages/rare
$Form.Controls.Add((generate_checkbox "Rare" "rare"))

# https://community.chocolatey.org/packages/Everything
$Form.Controls.Add((generate_checkbox "Everything" "everything"))

# https://community.chocolatey.org/packages/thunderbird
$Form.Controls.Add((generate_checkbox "Mozilla Thunderbird" "thunderbird"))

# https://community.chocolatey.org/packages/foobar2000
$Form.Controls.Add((generate_checkbox "foobar2000" "foobar2000"))

# https://community.chocolatey.org/packages/irfanview
$Form.Controls.Add((generate_checkbox "IrfanView" "irfanview"))

# https://community.chocolatey.org/packages/git
$Form.Controls.Add((generate_checkbox "Git" "git"))

# https://community.chocolatey.org/packages/mpv
$Form.Controls.Add((generate_checkbox "mpv" "mpv"))

# https://community.chocolatey.org/packages/vlc
$Form.Controls.Add((generate_checkbox "VLC" "vlc"))

# https://community.chocolatey.org/packages/putty
$Form.Controls.Add((generate_checkbox "PuTTY" "putty"))

# https://community.chocolatey.org/packages/teamspeak
$Form.Controls.Add((generate_checkbox "Teamspeak" "teamspeak"))

# https://community.chocolatey.org/packages/spotify
$Form.Controls.Add((generate_checkbox "Spotify" "spotify"))

# https://community.chocolatey.org/packages/obs-studio
$Form.Controls.Add((generate_checkbox "OBS Studio" "obs-studio"))

# https://community.chocolatey.org/packages/msiafterburner
$Form.Controls.Add((generate_checkbox "MSI Afterburner" "msiafterburner"))

# https://community.chocolatey.org/packages/cpu-z
$Form.Controls.Add((generate_checkbox "CPU-Z" "cpu-z"))

# https://community.chocolatey.org/packages/gpu-z
$Form.Controls.Add((generate_checkbox "GPU-Z" "gpu-z"))

# https://community.chocolatey.org/packages/notepadplusplus
$Form.Controls.Add((generate_checkbox "Notepad++" "notepadplusplus"))

# https://community.chocolatey.org/packages/vscode
$Form.Controls.Add((generate_checkbox "VSCode" "vscode"))

# https://community.chocolatey.org/packages/bulk-crap-uninstaller
$Form.Controls.Add((generate_checkbox "Bulk Crap Uninstaller" "bulk-crap-uninstaller"))

# https://community.chocolatey.org/packages/hwinfo
$Form.Controls.Add((generate_checkbox "HWiNFO" "hwinfo"))

# https://community.chocolatey.org/packages/kav
$Form.Controls.Add((generate_checkbox "Kaspersky Anti-Virus" "kav"))

# https://community.chocolatey.org/packages/microsoft-windows-terminal
$Form.Controls.Add((generate_checkbox "Windows Terminal" "microsoft-windows-terminal"))

if ($global:column -ne 0) {
    $global:lastPos += $separate
}

$Form.height = $global:lastPos + 80

# Detect internet connection
$InternetTest = (Test-Connection -ComputerName www.google.com -Quiet)
if (!$InternetTest) {
    [System.Windows.Forms.MessageBox]::Show("Internet connection not detected. Please check your network connection and try again.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Check if the system has dark mode or light mode set
$darkMode = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" | Select-Object -ExpandProperty "AppsUseLightTheme"
if ($darkMode -eq 0) {
    $Form.BackColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
    $Form.ForeColor = [System.Drawing.Color]::White
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
            $control.ForeColor = [System.Drawing.Color]::White
        }
    }
} else {
    $Form.BackColor = [System.Drawing.Color]::White
    $Form.ForeColor = [System.Drawing.Color]::Black
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::White
            $control.ForeColor = [System.Drawing.Color]::Black
        }
    }
}

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
        Start-Process -FilePath "$Env:ProgramData\chocolatey\choco.exe" -ArgumentList "install $($installPackages -join ' ') -y --force --allow-empty-checksums" -Wait
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
