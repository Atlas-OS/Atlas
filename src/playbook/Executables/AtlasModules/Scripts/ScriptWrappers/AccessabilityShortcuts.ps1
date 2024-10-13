[CmdletBinding()]
param()

function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Accessibility Shortcuts"
$form.Size = New-Object System.Drawing.Size(400, 400)
$form.StartPosition = "CenterScreen"

function Toggle-Process {
    param (
        [string]$processName,
        [scriptblock]$startCommand
    )
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Name $processName -Force
        Start-Sleep -Milliseconds 500
    } else {
        & $startCommand
    }
}

# Dark Mode/Light Mode Toggle
function dark_mode {
    $form.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
    $form.ForeColor = [System.Drawing.Color]::White
    foreach ($control in $form.Controls) {
        if ($control.GetType().Name -eq "Button") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
            $control.ForeColor = [System.Drawing.Color]::White
        }
    }
}

function light_mode {
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $form.ForeColor = [System.Drawing.Color]::Black
    foreach ($control in $form.Controls) {
        if ($control.GetType().Name -eq "Button") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
            $control.ForeColor = [System.Drawing.Color]::Black
        }
    }
}

$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$keyName = "AppsUseLightTheme"
function check_system_theme {
    if (((Get-ItemProperty -Path $registryPath -Name $keyName).$keyName) -eq 0) {
        dark_mode
        $toggleBtn.Text = "Light Mode"
    } else {
        light_mode
        $toggleBtn.Text = "Dark Mode"
    }
}

$toggleBtn = New-Object System.Windows.Forms.Button
$toggleBtn.Location = New-Object System.Drawing.Point(300, 10)
$toggleBtn.Size = New-Object System.Drawing.Size(80, 23)
$toggleBtn.Add_Click({
    if ($toggleBtn.Text -eq "Dark Mode") {
        $toggleBtn.Text = "Light Mode"
        dark_mode
    } else {
        $toggleBtn.Text = "Dark Mode"
        light_mode
    }
})
$form.Controls.Add($toggleBtn)

check_system_theme

$buttons = @(
    @{Text = "Toggle Narrator"; Shortcut = "Ctrl + Win + Enter"; Handler = {
        Toggle-Process -processName "Narrator" -startCommand { Start-Process "Narrator.exe" }
    }},
    @{Text = "Toggle Magnifier"; Shortcut = "Win + Plus/Minus"; Handler = {
        Toggle-Process -processName "Magnify" -startCommand { Start-Process "Magnify.exe" }
    }},
    @{Text = "Toggle High Contrast"; Shortcut = "Alt + Shift + Print Screen"; Handler = {
        Start-Process "ms-settings:easeofaccess-highcontrast"
    }},
    @{Text = "Open/Close On-Screen Keyboard"; Shortcut = "Win + Ctrl + O"; Handler = {
        Toggle-Process -processName "osk" -startCommand { Start-Process "osk.exe" }
    }},
    @{Text = "Sticky Keys Settings"; Shortcut = "Shift Key (pressed 5 times)"; Handler = {
        Start-Process "ms-settings:easeofaccess-keyboard"
    }}
)

$yPos = 50
foreach ($buttonInfo in $buttons) {
    $button = New-Object System.Windows.Forms.Button
    $button.Size = New-Object System.Drawing.Size(350, 40)
    $button.Location = New-Object System.Drawing.Point(20, $yPos)
    $button.Text = "$($buttonInfo.Text) ($($buttonInfo.Shortcut))"
    $button.Add_Click($buttonInfo.Handler)
    $form.Controls.Add($button)
    $yPos += 50
}

$form.Topmost = $true
[void]$form.ShowDialog()