[CmdletBinding()]
param (
    [switch]$RestartAfterUpdate
)

$script:SelectedUpdates = @()

function Test-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Restarting script with administrator privileges..."
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
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

    $Window = New-Object System.Windows.Window
    $Window.Title = "Select drivers to install"
    $Window.Width = 500
    $Window.Height = 400
    $Window.WindowStartupLocation = "CenterScreen"

    $StackPanel = New-Object System.Windows.Controls.StackPanel

    $ListBox = New-Object System.Windows.Controls.ListBox
    $ListBox.SelectionMode = "Extended"
    foreach ($update in $Updates) {
        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = $update.Title.ToString().Trim()
        $ListBox.Items.Add($item) | Out-Null
    }
    $StackPanel.Children.Add($ListBox) | Out-Null

    $OKButton = New-Object System.Windows.Controls.Button
    $OKButton.Content = "OK"
    $OKButton.Margin = "10,10,10,10"
    $OKButton.Add_Click({
        $Window.Tag = $ListBox.SelectedItems
        $Window.Close()
    })
    $StackPanel.Children.Add($OKButton) | Out-Null

    $Window.Content = $StackPanel
    $Window.ShowDialog() | Out-Null

    $selectedUpdates = @()
    foreach ($selected in $Window.Tag) {
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
    $Updates = Get-WUList -MicrosoftUpdate -Category "Drivers"
    
    if ($Updates.Count -gt 0) {
        Write-Host "Available driver updates:"
        $selection = Show-DriverSelection -Updates $Updates

        $selection = @($selection)
        
        if ($selection.Count -gt 0) {
            Write-Host "Installing selected driver updates..."
            $selection | Format-Table ComputerName, Status, KB, Size, Title -AutoSize
            $selection | Get-WUInstall -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
            Write-Host "Driver updates installed successfully!"

            $restartChoice = Read-Host "Do you want to restart now? (Y/N)"
            if ($restartChoice -match "^[Yy]$") {
                Write-Host "Restarting the system in 10 seconds..."
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            }
        }
        else {
            Write-Host "No drivers were selected for update."
        }
    }
    else {
        Write-Host "No driver updates found."
    }
}

Install-PSWindowsUpdateModule
Enable-MicrosoftUpdate
Update-Drivers

if (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Silent')) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
