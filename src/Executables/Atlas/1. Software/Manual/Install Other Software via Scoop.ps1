$ErrorActionPreference = 'SilentlyContinue'

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
    $checkbox.Location = new-object System.Drawing.Size(30, $global:lastPos)
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
$Form.Text = "Install Other Software via Scoop" # Titlebar
$Form.ShowIcon = $false
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.Size = New-Object System.Drawing.Size(250, 500)
$Form.AutoSizeMode = 0
$Form.KeyPreview = $True
$Form.SizeGripStyle = 2

# Label
$Label = New-Object System.Windows.Forms.label
$Label.Location = New-Object System.Drawing.Size(11, 15)
$Label.Size = New-Object System.Drawing.Size(255, 15)
$Label.Text = "Pick a browser:"
$Form.Controls.Add($Label)

# https://community.chocolatey.org/packages/discord
$Form.Controls.Add((generate_checkbox "Discord" "discord"))

# https://community.chocolatey.org/packages/discord-canary
$Form.Controls.Add((generate_checkbox "Discord Canary" "discord-canary"))

# https://community.chocolatey.org/packages/steam
$Form.Controls.Add((generate_checkbox "Steam" "steam"))

# https://community.chocolatey.org/packages/playnite
$Form.Controls.Add((generate_checkbox "Playnite" "playnite"))

# https://community.chocolatey.org/packages/bleachbit
$Form.Controls.Add((generate_checkbox "BleachBit" "bleachbit"))

# https://community.chocolatey.org/packages/notepadplusplus
$Form.Controls.Add((generate_checkbox "Notepad++" "notepadplusplus"))

# https://community.chocolatey.org/packages/msiafterburner
$Form.Controls.Add((generate_checkbox "MSI Afterburner" "msiafterburner"))

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

# https://community.chocolatey.org/packages/vscode
$Form.Controls.Add((generate_checkbox "VSCode" "vscode"))

# https://community.chocolatey.org/packages/putty
$Form.Controls.Add((generate_checkbox "PuTTY" "putty"))

# https://community.chocolatey.org/packages/ditto
$Form.Controls.Add((generate_checkbox "Ditto" "ditto"))

# https://community.chocolatey.org/packages/7zip
$Form.Controls.Add((generate_checkbox "7-Zip" "7zip"))

$Form.height = $global:lastPos + 80

$InstallButton = new-object System.Windows.Forms.Button
$InstallButton.Location = new-object System.Drawing.Size(($form.Width - 160 - 7), $global:lastPos)
$InstallButton.Size = new-object System.Drawing.Size(80, 23)
$InstallButton.Text = "Install"
$InstallButton.Add_Click({
    $global:install = $true
    $Form.Close()
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
        scoop install $installPackages --global
    }
}
Write-Host "`nCompleted.`n"
Pause