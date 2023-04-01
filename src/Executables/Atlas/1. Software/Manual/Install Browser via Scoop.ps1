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
$Form.Text = "Install Browser via Scoop" # Titlebar
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

# https://community.chocolatey.org/packages/ungoogled-chromium
$Form.Controls.Add((generate_checkbox "ungoogled-chromium" "ungoogled-chromium"))

# https://community.chocolatey.org/packages/Firefox
$Form.Controls.Add((generate_checkbox "Mozilla Firefox" "firefox"))

# https://community.chocolatey.org/packages/brave
$Form.Controls.Add((generate_checkbox "Brave Browser" "brave"))

# https://community.chocolatey.org/packages/GoogleChrome
$Form.Controls.Add((generate_checkbox "Google Chrome" "googlechrome"))

# https://community.chocolatey.org/packages/librewolf
$Form.Controls.Add((generate_checkbox "LibreWolf" "librewolf"))

# https://community.chocolatey.org/packages/tor-browser
$Form.Controls.Add((generate_checkbox "Tor Browser" "tor-browser"))

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