# Atlas.Software domain: interactive WinGet software picker.
#
# Ported from Internal\InstallSoftware.ps1 ("Install Software" in the Atlas folder).
# The old script-scoped state machine (column/lastPos/index globals) is replaced by a
# precomputed layout and form-attached state ($form.Tag), so no shared mutable
# variables are needed.

function Get-AtlasSoftwarePickerItem {
    <#
    .SYNOPSIS
        Returns the software catalog shown by the picker (display name + WinGet
        package id). Kept as a pure function for testability; StartAllBack replaces
        StartIsBack on Windows 11 (build 22000+).
    #>
    param(
        [int]$WindowsBuild = ([System.Environment]::OSVersion.Version.Build)
    )

    $items = @(
        @{ Text = 'Ungoogled Chromium'; Package = 'eloston.ungoogled-chromium' }
        @{ Text = 'Mozilla Firefox'; Package = 'Mozilla.Firefox' }
        @{ Text = 'Waterfox'; Package = 'Waterfox.Waterfox' }
        @{ Text = 'Brave Browser'; Package = 'Brave.Brave' }
        @{ Text = 'Google Chrome'; Package = 'Google.Chrome' }
        @{ Text = 'LibreWolf'; Package = 'LibreWolf.LibreWolf' }
        @{ Text = 'Tor Browser'; Package = 'TorProject.TorBrowser' }
        @{ Text = 'Discord'; Package = 'Discord.Discord' }
        @{ Text = 'Discord Canary'; Package = 'Discord.Discord.Canary' }
        @{ Text = 'Steam'; Package = 'Valve.Steam' }
        @{ Text = 'Playnite'; Package = 'Playnite.Playnite' }
        @{ Text = 'Heroic'; Package = 'HeroicGamesLauncher.HeroicGamesLauncher' }
        @{ Text = 'Everything'; Package = 'voidtools.Everything' }
        @{ Text = 'Mozilla Thunderbird'; Package = 'Mozilla.Thunderbird' }
        @{ Text = 'foobar2000'; Package = 'PeterPawlowski.foobar2000' }
        @{ Text = 'IrfanView'; Package = 'IrfanSkiljan.IrfanView' }
        @{ Text = 'Git'; Package = 'Git.Git' }
        @{ Text = 'VLC'; Package = 'VideoLAN.VLC' }
        @{ Text = 'PuTTY'; Package = 'PuTTY.PuTTY' }
        @{ Text = 'Ditto'; Package = 'Ditto.Ditto' }
        @{ Text = '7-Zip'; Package = '7zip.7zip' }
        @{ Text = 'Teamspeak'; Package = 'TeamSpeakSystems.TeamSpeakClient' }
        @{ Text = 'Spotify'; Package = 'Spotify.Spotify' }
        @{ Text = 'OBS Studio'; Package = 'OBSProject.OBSStudio' }
        @{ Text = 'MSI Afterburner'; Package = 'Guru3D.Afterburner' }
        @{ Text = 'NVCleanstall'; Package = 'TechPowerUp.NVCleanstall' }
        @{ Text = 'CPU-Z'; Package = 'CPUID.CPU-Z' }
        @{ Text = 'GPU-Z'; Package = 'TechPowerUp.GPU-Z' }
        @{ Text = 'Notepad++'; Package = 'Notepad++.Notepad++' }
        @{ Text = 'VSCode'; Package = 'Microsoft.VisualStudioCode' }
        @{ Text = 'VSCodium'; Package = 'VSCodium.VSCodium' }
        @{ Text = 'BCUninstaller'; Package = 'Klocman.BulkCrapUninstaller' }
        @{ Text = 'HWiNFO'; Package = 'REALiX.HWiNFO' }
        @{ Text = 'Lightshot'; Package = 'Skillbrains.Lightshot' }
        @{ Text = 'ShareX'; Package = 'ShareX.ShareX' }
        @{ Text = 'Snipping Tool'; Package = '9MZ95KL8MR0L' }
        @{ Text = 'ExplorerPatcher'; Package = 'valinet.ExplorerPatcher' }
        @{ Text = 'Powershell 7'; Package = 'Microsoft.PowerShell' }
        @{ Text = 'UniGetUI'; Package = 'MartiCliment.UniGetUI' }
    )

    if ($WindowsBuild -ge 22000) {
        $items += @{ Text = 'StartAllBack'; Package = 'StartIsBack.StartAllBack' }
    }
    else {
        $items += @{ Text = 'StartIsBack'; Package = 'StartIsBack.StartIsBack' }
    }

    return @($items | ForEach-Object { [pscustomobject]$_ })
}

function Set-AtlasSoftwarePickerTheme {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]$Form,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Dark', 'Light')]
        [string]$Theme
    )

    if ($Theme -eq 'Dark') {
        $backColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
        $foreColor = [System.Drawing.Color]::White
    }
    else {
        $backColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $foreColor = [System.Drawing.Color]::Black
    }

    $Form.BackColor = $backColor
    $Form.ForeColor = $foreColor
    foreach ($control in $Form.Controls) {
        if ($control -is [System.Windows.Forms.CheckBox]) {
            $control.BackColor = $backColor
            $control.ForeColor = $foreColor
        }
    }
}

function Show-AtlasSoftwarePicker {
    <#
    .SYNOPSIS
        Shows the Atlas software picker and installs the selected packages with WinGet.
        Returns $false when WinGet is unavailable (wingetCheck.cmd failed), $true
        otherwise.
    #>
    $wingetCheck = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\wingetCheck.cmd'
    & $wingetCheck
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    Clear-Host
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $items = @(Get-AtlasSoftwarePickerItem)

    # Two-column layout: x = 30 / 300, y starts at 50 with 30px spacing.
    $rowSpacing = 30
    $firstColumnCount = [math]::Ceiling($items.Count / 2)
    $secondColumnCount = $items.Count - $firstColumnCount

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Install Software | Atlas'
    $form.ShowIcon = $false
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.Size = New-Object System.Drawing.Size(600, 210)
    $form.AutoSizeMode = 0
    $form.KeyPreview = $true
    $form.SizeGripStyle = 2
    $form.Tag = @{ Install = $false }

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(11, 15)
    $label.Size = New-Object System.Drawing.Size(255, 15)
    $label.Text = 'Download and install software using WinGet:'
    $form.Controls.Add($label)

    for ($index = 0; $index -lt $items.Count; $index++) {
        $column = if ($index -ge $firstColumnCount) { 1 } else { 0 }
        $row = if ($column -eq 0) { $index } else { $index - $firstColumnCount }

        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Location = New-Object System.Drawing.Size((30 + ($column * 270)), (50 + ($row * $rowSpacing)))
        $checkbox.Size = New-Object System.Drawing.Size(250, 18)
        $checkbox.Text = $items[$index].Text
        $checkbox.Name = $items[$index].Package
        $form.Controls.Add($checkbox)
    }

    $buttonsTop = 50 + ($secondColumnCount * $rowSpacing)
    if ($secondColumnCount -gt 0) {
        $buttonsTop += $rowSpacing
    }
    $form.Height = $buttonsTop + 80

    # Dark Mode/Light Mode toggle
    $toggleButton = New-Object System.Windows.Forms.Button
    $toggleButton.Location = New-Object System.Drawing.Point(500, 20)
    $toggleButton.Size = New-Object System.Drawing.Size(80, 23)
    $toggleButton.Add_Click({
        if ($this.Text -eq 'Dark Mode') {
            $this.Text = 'Light Mode'
            Set-AtlasSoftwarePickerTheme -Form $this.FindForm() -Theme 'Dark'
        }
        else {
            $this.Text = 'Dark Mode'
            Set-AtlasSoftwarePickerTheme -Form $this.FindForm() -Theme 'Light'
        }
    })
    $form.Controls.Add($toggleButton)

    # Match the system "app" theme initially
    $appsUseLightTheme = 1
    try {
        $appsUseLightTheme = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -ErrorAction Stop).AppsUseLightTheme
    }
    catch {
        $appsUseLightTheme = 1
    }
    if ($appsUseLightTheme -eq 0) {
        Set-AtlasSoftwarePickerTheme -Form $form -Theme 'Dark'
        $toggleButton.Text = 'Light Mode'
    }
    else {
        Set-AtlasSoftwarePickerTheme -Form $form -Theme 'Light'
        $toggleButton.Text = 'Dark Mode'
    }

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Size(($form.Width - 80 - 31), $buttonsTop)
    $installButton.Size = New-Object System.Drawing.Size(80, 23)
    $installButton.Text = 'Install'
    $installButton.Add_Click({
        $parentForm = $this.FindForm()
        $checkedBoxes = @($parentForm.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked })
        if ($checkedBoxes.Count -eq 0) {
            Read-MessageBox -Title 'No package selected' -Body 'Please select at least one software package to install' -Icon Information -Buttons Ok | Out-Null
        }
        else {
            $parentForm.Tag.Install = $true
            $parentForm.Close()
        }
    })
    $form.Controls.Add($installButton)

    $form.Add_Shown({ $this.Activate() })
    [void]$form.ShowDialog()

    if ($form.Tag.Install) {
        $installPackages = @($form.Controls |
            Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } |
            Select-Object -ExpandProperty Name)

        if ($installPackages.Count -ne 0) {
            Write-Host 'Installing: ' -ForegroundColor Yellow
            foreach ($package in $installPackages) {
                Write-Host '- ' -NoNewline -ForegroundColor Blue
                Write-Host $package
            }
            Write-Host ''
            Start-Sleep 1
            foreach ($package in $installPackages) {
                & winget install -e --id $package --accept-package-agreements --accept-source-agreements --disable-interactivity --force -h | Out-Host
            }
            Write-Host ''
            Read-Pause
        }
    }

    $form.Dispose()
    return $true
}
