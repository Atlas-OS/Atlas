[CmdletBinding()]
param (
    [switch]$RestartAfterUpdate
)

function Install-PSWindowsUpdateModule {
    # Make sure that PowerShellGet is updated just in case 
    if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
        Install-Module -Name PowerShellGet -Force -AllowClobber -Confirm:$false -Scope AllUsers
    }

    # Making it trusted now will avoid further user prompts in the future
    if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne "Trusted") {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    # Install PSWindowsUpdate
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -Confirm:$false
    }
}

function Enable-MicrosoftUpdate {
    Write-Host "Enabling Microsoft Update for driver updates..."
    Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$false | Out-Null
}

function Update-Drivers {
    Write-Host "Checking for driver updates..."
    $Updates = Get-WUList -MicrosoftUpdate -Category "Drivers"

    if ($Updates.Count -gt 0) {
        Write-Host "Installing available driver updates..."
        $Updates | Format-Table ComputerName, Status, KB, Size, Title -AutoSize
        Get-WUInstall -MicrosoftUpdate -Category "Drivers" -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
        Write-Host "Driver updates installed successfully!"
        
        # Restart if needed
        if ($RestartAfterUpdate) {
            Write-Host "Restarting the system in 10 seconds..."
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        }
    } else {
        Write-Host "No driver updates found."
    }
}

Install-PSWindowsUpdateModule
Enable-MicrosoftUpdate
Update-Drivers

Write-Host "Driver update process completed."
