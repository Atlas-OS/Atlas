# Atlas.Software domain: interactive WinGet software picker.
#
# The layout is precomputed and UI state lives on the form ($form.Tag), so no shared
# mutable variables are needed.

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

    return @($items | ForEach-Object {
            [pscustomobject]@{
                Text    = $_.Text
                Package = $_.Package
                # Microsoft Store product IDs are 12-character values beginning
                # with 9. All named packages in this catalog use the community
                # source. Pinning the source prevents a user-added source from
                # satisfying an otherwise exact package ID.
                Source  = if ($_.Package -match '^9[A-Z0-9]{11}$') { 'msstore' } else { 'winget' }
            }
        })
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

function Invoke-AtlasSoftwarePickerPackageInstall {
    <#
    .SYNOPSIS
        Brokers one selected package through the medium-integrity Explorer shell.
    .DESCRIPTION
        The InstallSoftware toggle is intentionally medium-integrity. Keep WinGet
        in this process, validate the exact built-in source immediately before
        installation, and trust the real native exit code rather than a writable
        side-channel result file.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,199}$')]
        [string]$PackageId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('winget', 'msstore')]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        $AtlasContext
    )

    $downloadIntegrity = [IO.Path]::Combine(
        $AtlasContext.AtlasModulesPath,
        'Scripts',
        'Internal',
        'Download-Integrity.ps1'
    )
    if (-not [IO.File]::Exists($downloadIntegrity)) {
        throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
    }
    . $downloadIntegrity

    $wingetPath = Get-AtlasTrustedWingetPath
    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name $Source
    & $wingetPath install --exact --id $PackageId --source $Source `
        --accept-package-agreements --accept-source-agreements `
        --disable-interactivity --silent
    $wingetExitCode = $LASTEXITCODE
    if ($wingetExitCode -ne 0) {
        throw "WinGet failed to install '$PackageId' from '$Source' with exit code $wingetExitCode."
    }
}

function Invoke-AtlasSoftwarePickerPackageBatch {
    <#
    .SYNOPSIS
        Attempts every selected package and returns a failure record for each
        package that could not be installed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$PackageId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Catalog,

        [Parameter(Mandatory = $true)]
        $AtlasContext
    )

    $failures = New-Object 'System.Collections.Generic.List[object]'
    foreach ($package in $PackageId) {
        try {
            $catalogItem = $Catalog | Where-Object { $_.Package -ceq $package } | Select-Object -First 1
            if ($null -eq $catalogItem) {
                throw "Package '$package' is not present in the Atlas software catalog."
            }
            if ($catalogItem.Source -notin @('winget', 'msstore')) {
                throw "No trusted WinGet source is declared for package '$package'."
            }

            $null = Invoke-AtlasSoftwarePickerPackageInstall `
                -PackageId $package -Source $catalogItem.Source -AtlasContext $AtlasContext
        }
        catch {
            $message = $_.Exception.Message
            Write-Warning "Failed to install '$package': $message"
            $failures.Add([pscustomobject]@{
                    PackageId = $package
                    Message   = $message
                })
        }
    }

    return $failures.ToArray()
}

function Show-AtlasSoftwarePicker {
    <#
    .SYNOPSIS
        Shows the Atlas software picker and installs the selected packages with WinGet.
        Returns $false when WinGet is unavailable (Test-Winget.cmd failed), $true
        otherwise.
    #>
    $atlasContext = Get-AtlasContext
    $trustBootstrap = [IO.Path]::Combine(
        $atlasContext.AtlasModulesPath,
        'Scripts',
        'Internal',
        'Initialize-PowerShellTrust.ps1'
    )
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap

    $downloadIntegrity = [IO.Path]::Combine(
        $atlasContext.AtlasModulesPath,
        'Scripts',
        'Internal',
        'Download-Integrity.ps1'
    )
    if (-not [IO.File]::Exists($downloadIntegrity)) {
        throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
    }
    . $downloadIntegrity
    try {
        $wingetPath = Get-AtlasTrustedWingetPath
        Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name winget
    }
    catch {
        Write-Warning "WinGet is unavailable: $($_.Exception.Message)"
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

    try {
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
                $failures = @(Invoke-AtlasSoftwarePickerPackageBatch `
                        -PackageId $installPackages -Catalog $items -AtlasContext $atlasContext)
                Write-Host ''
                Read-Pause
                if ($failures.Count -ne 0) {
                    $summary = @($failures | ForEach-Object { "- $($_.PackageId): $($_.Message)" }) -join [Environment]::NewLine
                    throw "$($failures.Count) selected software package(s) failed to install:$([Environment]::NewLine)$summary"
                }
            }
        }
    }
    finally {
        $form.Dispose()
    }
    return $true
}
