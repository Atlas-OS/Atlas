[CmdletBinding()]
param (
    [switch]$RestartAfterUpdate,
    [switch]$Silent
)

function Test-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Restarting script with administrator privileges..."

        $arguments = @(
            "-ExecutionPolicy RemoteSigned",
            "-NoProfile",
            "-File `"$PSCommandPath`""
        )
        if ($RestartAfterUpdate) {
            $arguments += "-RestartAfterUpdate"
        }
        if ($Silent) {
            $arguments += "-Silent"
        }

        Start-Process -FilePath "powershell" -ArgumentList ($arguments -join " ") -Verb RunAs
        exit
    }
}
Test-Admin

function Install-PSWindowsUpdateModule {
    if (-not (Get-PackageProvider -ListAvailable | Where-Object Name -eq "NuGet")) {
        Install-PackageProvider -Name NuGet -Force -Confirm:$false
    }
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -Confirm:$false
    }
}

function Enable-MicrosoftUpdate {
    Write-Host "Enabling Microsoft Update for driver updates..."
    Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false | Out-Null
}

function Show-DriverSelection {
    param (
        [array]$Updates
    )

    if ($Updates.Count -eq 0) {
        return @()
    }

    Add-Type -AssemblyName PresentationFramework

    $window = New-Object System.Windows.Window
    $window.Title = "Select drivers to install"
    $window.Width = 500
    $window.Height = 400
    $window.WindowStartupLocation = "CenterScreen"

    $stackPanel = New-Object System.Windows.Controls.StackPanel

    $listBox = New-Object System.Windows.Controls.ListBox
    $listBox.SelectionMode = "Extended"
    foreach ($update in $Updates) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = $update.Title.ToString().Trim()
        $listBox.Items.Add($item) | Out-Null
    }
    $stackPanel.Children.Add($listBox) | Out-Null

    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Margin = "10,10,10,10"
    $okButton.Add_Click({
            $window.Tag = $listBox.SelectedItems
            $window.Close()
        })
    $stackPanel.Children.Add($okButton) | Out-Null

    $window.Content = $stackPanel
    $window.ShowDialog() | Out-Null

    $selectedUpdates = @()
    foreach ($selected in $window.Tag) {
        $title = $selected.Content
        $update = $Updates | Where-Object { $_.Title.ToString().Trim() -eq $title }
        if ($update) {
            $selectedUpdates += $update
        }
    }

    return $selectedUpdates
}

function Update-Drivers {
    Write-Host "Checking for driver updates..."
    try {
        $updates = @(Get-WUList -MicrosoftUpdate -Category "Drivers" -ErrorAction Stop)
    }
    catch {
        Write-Error "Failed to query driver updates: $($_.Exception.Message)"
        return $false
    }

    if ($updates.Count -eq 0) {
        Write-Host "No driver updates found."
        return $true
    }

    Write-Host "Available driver updates:"

    if ($Silent) {
        Write-Host "Silent mode enabled; selecting all available driver updates."
        $selection = $updates
    }
    else {
        $selection = @(Show-DriverSelection -Updates $updates)
    }

    if ($selection.Count -eq 0) {
        Write-Host "No drivers were selected for update."
        return $true
    }

    Write-Host "Installing selected driver updates..."
    $selection | Format-Table ComputerName, Status, KB, Size, Title -AutoSize

    try {
        $selection | Get-WUInstall -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Driver update installation failed: $($_.Exception.Message)"
        return $false
    }

    Write-Host "Driver updates installed successfully!"

    if ($RestartAfterUpdate) {
        Write-Host "RestartAfterUpdate is enabled. Restarting the system in 10 seconds..."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        return $true
    }

    if (-not $Silent) {
        $restartChoice = Read-Host "Do you want to restart now? (Y/N)"
        if ($restartChoice -match "^[Yy]$") {
            Write-Host "Restarting the system in 10 seconds..."
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        }
    }

    return $true
}

$scriptSucceeded = $false
try {
    Install-PSWindowsUpdateModule
    Enable-MicrosoftUpdate
    $scriptSucceeded = Update-Drivers
}
catch {
    Write-Error "Driver update process failed: $($_.Exception.Message)"
    exit 1
}

if (-not $scriptSucceeded) {
    exit 1
}

if (-not $Silent) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
